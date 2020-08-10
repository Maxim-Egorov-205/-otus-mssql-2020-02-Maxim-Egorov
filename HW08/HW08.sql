
/*
1. �������� ������ � ��������� �������� � ���������� ��� � ��������� ����������. �������� �����.
� �������� ������� � ��������� �������� � ��������� ���������� ����� ����� ���� ������ ��� ��������� ������:

������� ������ ����� ������ ����������� ������ �� ������� � 2015 ���� (� ������ ������ ������ �� ����� ����������, ��������� ����� � ������� ������� �������)
�������� id �������, �������� �������, ���� �������, ����� �������, ����� ����������� ������
������
���� ������� ����������� ���� �� ������
2015-01-29 4801725.31
2015-01-30 4801725.31
2015-01-31 4801725.31
2015-02-01 9626342.98
2015-02-02 9626342.98
2015-02-03 9626342.98
������� ����� ����� �� ������� Invoices.
����������� ���� ������ ���� ��� ������� �������.
*/

--1.1. ������ � ��������� ��������
SET STATISTICS TIME ON
--�������� ������� � ������ ������ �� ������� ������� �� ����� � �������
DROP TABLE IF EXISTS #SumCustomerSales   

SELECT c.CustomerID,
       YEAR(i.InvoiceDate) AS y,
	   MONTH(i.InvoiceDate) AS m,
	   SUM(il.QuantitY*il.UnitPrice) SumRealize
INTO #SumCustomerSales
FROM Sales.Invoices i
		JOIN sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID 
		JOIN sales.Customers c ON i.CustomerID=c.CustomerID
WHERE YEAR(i.InvoiceDate)>=2015
GROUP BY c.CustomerID,
         YEAR(i.InvoiceDate), 
	     MONTH(i.InvoiceDate) 

--�������� ������
SELECT i.InvoiceID,
	   c.CustomerName,
	   i.InvoiceDate,
	   cs.SumRealize
FROM Sales.Invoices i
		JOIN sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID 
		JOIN sales.Customers c
			ON i.CustomerID=c.CustomerID
		JOIN #SumCustomerSales cs 
			ON c.CustomerID=cs.CustomerID and YEAR(i.InvoiceDate)=cs.y and MONTH(i.InvoiceDate)=cs.m
WHERE YEAR(i.InvoiceDate)>=2015
ORDER BY c.CustomerName,
	     i.InvoiceDate
------------------------------------
--1.2. ������ � ��������� ����������
------------------------------------
--��������� ���������� � ������ ������ �� ������� ������� �� ����� � �������
SET STATISTICS TIME ON
--��������� ���������� � ������ ������ �� ������� ������� �� ����� � �������
DECLARE @SumCustomerSales TABLE (CustomerID INT , y INT, m INT, SumRealize DECIMAL(18,2))
INSERT INTO @SumCustomerSales
SELECT c.CustomerID,
       YEAR(i.InvoiceDate) AS y,
	   MONTH(i.InvoiceDate) AS m,
	   SUM(il.QuantitY*il.UnitPrice) SumRealize
FROM Sales.Invoices i
		JOIN sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID 
		JOIN sales.Customers c ON i.CustomerID=c.CustomerID
WHERE YEAR(i.InvoiceDate)>=2015
GROUP BY c.CustomerID,
         YEAR(i.InvoiceDate), 
	     MONTH(i.InvoiceDate) 

--�������� ������
SELECT i.InvoiceID,
	   c.CustomerName,
	   i.InvoiceDate,
	   cs.SumRealize
FROM Sales.Invoices i
		JOIN sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID 
		JOIN sales.Customers c
			ON i.CustomerID=c.CustomerID
		JOIN @SumCustomerSales cs 
			ON c.CustomerID=cs.CustomerID and YEAR(i.InvoiceDate)=cs.y and MONTH(i.InvoiceDate)=cs.m
WHERE YEAR(i.InvoiceDate)>=2015
ORDER BY c.CustomerName,
	     i.InvoiceDate
--�����:
--����� �������� ����������
--������ � ��������� ���������� ������� ��-�� ���� �������� � ����� ����� ����������  ������� ������� (������ ���� ��� join � ��������� ����������)- index seek, key lookup, index seek
--option recompile �������� ���������� ������� � ��������� ����������
--����� ���������� ������� � ��������� ���������� ����� ������� ������ , ���� ���� ������������ option(recompile)

--2. ���� �� ����� ������������ ���� ������, �� �������� ������ ����� ����������� ������ � ������� ������� �������.
--�������� 2 �������� ������� - ����� windows function � ��� ���. �������� ����� ������� �����������, �������� �� set statistics time on;
SET STATISTICS TIME ON

SELECT i.InvoiceID,
	   c.CustomerName,
	   i.InvoiceDate,
	   SUM(il.QuantitY*il.UnitPrice) OVER(PARTITION BY YEAR(i.InvoiceDate),MONTH(i.InvoiceDate),c.CustomerName) AS SumRealize
FROM Sales.Invoices i
		JOIN sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID 
		JOIN sales.Customers c
			ON i.CustomerID=c.CustomerID
WHERE YEAR(i.InvoiceDate)>=2015
ORDER BY c.CustomerName,
	     i.InvoiceDate
/*
���������� ���������� ��������:
��������� �������:	
 ����� ������ SQL Server:
   ����� �� = 187 ��, ����������� ����� = 1049 ��.

��������� ����������:
 ����� ������ SQL Server:
   ����� �� = 1953 ��, ����������� ����� = 2672 ��.
 
������� �������:
 ����� ������ SQL Server:
   ����� �� = 282 ��, ����������� ����� = 1169 ��.	

����� �� �������� ���������� ������� (�� ��������):
	��������� �������
	��������� ����������
	������� �������

*/

--3. ������� ������ 2� ����� ���������� ��������� (�� ���-�� ���������)
-- � ������ ������ �� 2016� ��� (�� 2 ����� ���������� �������� � ������ ������)

---��������� ��������� ��������� 
WITH CTE_TOP2 AS
(
	SELECT YEAR(i.InvoiceDate) y,
		   MONTH(i.InvoiceDate) m,
		   S.StockItemName,
		   ROW_NUMBER ()  OVER (PARTITION BY  YEAR(i.InvoiceDate), MONTH(i.InvoiceDate) ORDER BY sum(il.QuantitY) DESC)  AS rown
	FROM Sales.Invoices i
			JOIN sales.InvoiceLines il
				ON il.InvoiceID = i.InvoiceID 
			JOIN Warehouse.StockItems s
				ON s.StockItemID = il.StockItemID
	WHERE YEAR(i.InvoiceDate)=2016
	GROUP BY YEAR(i.InvoiceDate),
			 MONTH(i.InvoiceDate),
			 S.StockItemName
)
--�������� select �� ���������� ���������
SELECT y,
	   m,
       StockItemName
FROM CTE_TOP2
WHERE rown<=2
order by y,
	     m,
		 rown desc

/*
4. ������� ����� ��������
���������� �� ������� �������, � ����� ����� ������ ������� �� ������, ��������, ����� � ����
������������ ������ �� �������� ������, ��� ����� ��� ��������� ����� �������� ��������� ���������� ������
���������� ����� ���������� ������� � �������� ����� � ���� �� �������
���������� ����� ���������� ������� � ����������� �� ������ ����� �������� ������
���������� ��������� id ������ ������ �� ����, ��� ������� ����������� ������� �� ����� 
���������� �� ������ � ��� �� �������� ����������� (�� �����)
�������� ������ 2 ������ �����, � ������ ���� ���������� ������ ��� ����� ������� "No items"

����������� 30 ����� ������� �� ���� ��� ������ �� 1 ��
��� ���� ������ �� ����� ������ ������ ��� ������������� �������
*/

SELECT s.StockItemID, 
	   s.StockItemName,
	   s.Brand,
	   s.UnitPrice,
	   ROW_NUMBER () OVER (PARTITION BY LEFT(s.StockItemName,1) ORDER BY LEFT(s.StockItemName,1)) AS Rown_name,    --������������ ������ �� �������� ������, ��� ����� ��� ��������� ����� �������� ��������� ���������� ������     
	   COUNT(s.StockItemID)  OVER () AS All_Qtty, --����� ���������� �������
	   COUNT(s.StockItemID)  OVER (PARTITION BY LEFT(s.StockItemName,1)) AS First_Symb_Qtty, --����� ���������� ������� � ����������� �� ������ ����� �������� ������
	   LEAD(s.StockItemID) over (ORDER BY s.StockItemName) AS Next_ID, --��������� id ������
	   LAG(s.StockItemID) over (ORDER BY s.StockItemName) AS Prev_ID, --���������� id ������
	   ISNULL(LAG(s.StockItemName,2) over (ORDER BY s.StockItemName),'No items') AS Prev_Two_Symb_ID, --���������� id ������ 2 ������ �����
	   NTILE(30)  OVER (ORDER BY s.TypicalWeightPerUnit) AS Group_per_weight, --30 ����� ������� �� ���� ��� ������ �� 1 ��
	   s.TypicalWeightPerUnit
FROM Warehouse.StockItems s
order by s.TypicalWeightPerUnit

--5. �� ������� ���������� �������� ���������� �������, �������� ��������� ���-�� ������
--� ����������� ������ ���� �� � ������� ����������, �� � �������� �������, ���� �������, ����� ������
SELECT PersonID,
	   LastName, 
	   CustomerID,
       CustomerName,
	   InvoiceDate,
	   SumSale
FROM
(
	SELECT p.PersonID,
		   SUBSTRING(p.FullName,CHARINDEX(' ',p.FullName),LEN(p.FullName)) AS LastName, --������� ����������
		   c.CustomerID,
		   c.CustomerName,
		   i.InvoiceID,
		   i.InvoiceDate,
		   SUM(il.QuantitY*il.UnitPrice) AS SumSale,
		   ROW_NUMBER () OVER (PARTITION BY p.PersonID ORDER BY i.InvoiceDate DESC, i.InvoiceID DESC) AS ROWN
	FROM sales.invoices i
		JOIN sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID 
		JOIN sales.Customers c
			ON i.CustomerID=c.CustomerID	
		JOIN [Application].[People] p
			ON i.SalespersonPersonID=p.PersonID
	GROUP BY p.PersonID, 
			 SUBSTRING(p.FullName,CHARINDEX(' ',p.FullName),LEN(p.FullName)),
			 c.CustomerID,
			 c.CustomerName,
			 i.InvoiceDate,
			 i.InvoiceID
) AS LastSale
WHERE ROWN = 1


--6. �������� �� ������� ������� 2 ����� ������� ������, ������� �� �������
--� ����������� ������ ���� �� ������, ��� ��������, �� ������, ����, ���� �������

SELECT CustomerID,
	   CustomerName,
	   StockItemID,                 
	   UnitPrice,
	   InvoiceDate
FROM
(
	SELECT 
		   c.CustomerID,
		   c.CustomerName,
		   s.StockItemID,                 
		   il.UnitPrice,
		   MAX(i.InvoiceDate) AS InvoiceDate,
		   ROW_NUMBER () OVER (PARTITION BY c.CustomerName ORDER BY il.UnitPrice DESC) AS ROWN
	FROM sales.invoices i
		JOIN sales.InvoiceLines il
			ON il.InvoiceID = i.InvoiceID 
		JOIN sales.Customers c
			ON i.CustomerID=c.CustomerID	
		JOIN [Application].[People] p
			ON i.SalespersonPersonID=p.PersonID
		JOIN Warehouse.StockItems s
				ON s.StockItemID = il.StockItemID
	GROUP BY   c.CustomerID,
			   c.CustomerName,
			   s.StockItemID,                 
			   il.UnitPrice
) AS Top2_price
WHERE ROWN<=2
ORDER BY CustomerName,
         UnitPrice DESC