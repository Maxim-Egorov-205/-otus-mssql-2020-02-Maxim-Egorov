--1. �������� �����������, ������� �������� ������������, � ��� �� ������� �� ����� �������.
--1.1.����� ��������� ������
SELECT p.PersonID,
	   p.FullName
FROM [Application].[People] p
WHERE  NOT EXISTS (SELECT o.SalespersonPersonID  FROM SALES.ORDERS o WHERE p.PersonID=o.SalespersonPersonID)
   AND p.IsSalesperson=1 --����������

--1.2.����� WITH (��� ����������� ������)
WITH CteSalesPersonOrders AS                                            --��� id �����������, ������� ��������� ������
(
	SELECT  DISTINCT SalespersonPersonID
	FROM Sales.Orders
)
SELECT p.PersonID,
	   p.FullName
FROM [Application].[People] p
	LEFT JOIN CteSalesPersonOrders c
		ON p.PersonID=c.SalespersonPersonID	
WHERE c.SalespersonPersonID IS NULL
	AND p.IsSalesperson=1 --����������

--2. �������� ������ � ����������� ����� (�����������), 2 �������� ����������.
--2.1.
SELECT s.StockItemID,
	   s.StockItemName
FROM [Warehouse].[StockItems] s
WHERE S.UnitPrice IN (SELECT TOP 1 UnitPrice FROM [Warehouse].[StockItems]  ORDER BY UnitPrice ASC)

--2.2.
SELECT s.StockItemID,
	   s.StockItemName
FROM [Warehouse].[StockItems] s
WHERE S.UnitPrice IN (SELECT MIN(UnitPrice) FROM [Warehouse].[StockItems])

--2.3.����� WITH (��� ����������� ������)
WITH CteMinUnitPrice AS              
(
	SELECT MIN(UnitPrice) AS UnitPrice
	FROM [Warehouse].[StockItems]
)
SELECT s.StockItemID,
	   s.StockItemName
FROM [Warehouse].[StockItems] s
JOIN CteMinUnitPrice c
	ON s.UnitPrice=c.UnitPrice

--3. �������� ���������� �� ��������, ������� �������� �������� 5 ������������
--�������� �� [Sales].[CustomerTransactions] ����������� 3 ������� (� ��� ����� � CTE)
--3.1 c CTE
WITH CteMaxTransactionAmount AS              --5 ������������ ��������  �������� 
(
	SELECT TOP 5 CustomerID
	FROM [Sales].[CustomerTransactions] 
	ORDER BY TransactionAmount DESC
)
SELECT DISTINCT c.CustomerID,
			    c.CustomerName
FROM Sales.Customers c
	JOIN CteMaxTransactionAmount ct ON c.CustomerID=ct.CustomerID

--3.2 ������� � IN
SELECT c.CustomerID,
	   c.CustomerName
FROM Sales.Customers c
WHERE c.CustomerID IN 
	(
	SELECT TOP 5 CustomerID
	FROM [Sales].[CustomerTransactions] 
	ORDER BY TransactionAmount DESC
	)

--3.3 ������� � cte,exists
WITH CteMaxTransactionAmount AS             
(
	SELECT TOP 5 CustomerID
	FROM [Sales].[CustomerTransactions] 
	ORDER BY TransactionAmount DESC
)
SELECT c.CustomerID,
	   c.CustomerName
FROM Sales.Customers c
WHERE EXISTS (SELECT CustomerID FROM CteMaxTransactionAmount ct where ct.CustomerID=c.CustomerID) 

--4. �������� ������ (�� � ��������), � ������� ���� ���������� ������,
--�������� � ������ ����� ������� �������, � ����� ��� ����������, ������� ����������� �������� �������
--4.1. with
WITH CteMaxUnitPrice AS                            
(
	SELECT TOP 3 StockItemID
	FROM [Warehouse].[StockItems]
	ORDER BY UnitPrice DESC
)
SELECT DISTINCT ct.CityID,
		        ct.CityName,
		        p.FullName	 
FROM sales.orders o
	JOIN Sales.OrderLines ol
		ON o.OrderID=ol.OrderID               
	JOIN CteMaxUnitPrice m
		ON ol.StockItemID = m.StockItemID     
	JOIN Sales.Customers c
		ON  o.CustomerID=c.CustomerID
	JOIN Application.Cities ct 
		ON  c.DeliveryCityID=ct.CityId  
	JOIN Sales.Invoices i 
		ON o.OrderID=i.OrderID	  		    
    JOIN Application.People	p
		ON i.PackedByPersonID=p.PersonID    
ORDER BY ct.CityID,
	     p.FullName		                                    											
--4.2. �����������
SELECT DISTINCT ct.CityID,
		        ct.CityName,
		        p.FullName	 
FROM sales.orders o
	JOIN Sales.OrderLines ol
		ON o.OrderID=ol.OrderID                   
	JOIN Sales.Customers c
		ON  o.CustomerID=c.CustomerID
	JOIN Application.Cities ct 
		ON  c.DeliveryCityID=ct.CityId   
	JOIN Sales.Invoices i 
		ON o.OrderID=i.OrderID	  		    
    JOIN Application.People	p
		ON i.PackedByPersonID=p.PersonID       	                                   											
WHERE EXISTS 
	(
		SELECT m.StockItemID
		FROM (
				SELECT TOP 3 StockItemID
				FROM [Warehouse].[StockItems]
				 ORDER BY UnitPrice DESC
			  ) m
		WHERE ol.StockItemID = m.StockItemID
	)
ORDER BY ct.CityID,
	     p.FullName	