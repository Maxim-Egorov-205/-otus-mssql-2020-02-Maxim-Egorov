--1. ��������� �������� ������, ������� � ���������� ������ ���������� ��������� ������� ���������� ����:
--�������� �������
--�������� ���������� �������
--�������� ����� � ID 2-6, ��� ��� ������������� Tailspin Toys
--��� ������� ����� �������� ��� ����� �������� ������ ���������
--�������� �������� Tailspin Toys (Gasport, NY) - �� �������� � ����� ������ Gasport,NY
--���� ������ ����� ������ dd.mm.yyyy �������� 25.12.2019
--��������, ��� ������ ��������� ����������:
--InvoiceMonth Peeples Valley, AZ Medicine Lodge, KS Gasport, NY Sylvanite, MT Jessie, ND
--01.01.2013 3 1 4 2 2
--01.02.2013 7 3 4 2 1

SELECT InvoiceMonth, [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT],[Jessie, ND]
FROM
(
	SELECT SUBSTRING(c.CustomerName,CHARINDEX('(',c.CustomerName)+1,CHARINDEX(')',c.CustomerName)-CHARINDEX('(',c.CustomerName)-1) AS ShortName,
		   CONVERT(varchar,dateadd(day, - datepart(day, i.InvoiceDate) + 1, convert(date, i.InvoiceDate)),104) AS InvoiceMonth, 
		   il.QuantitY AS Qtty
	FROM sales.Customers c 
			JOIN Sales.Invoices i
				ON i.CustomerID=c.CustomerID
			JOIN sales.InvoiceLines il
				ON il.InvoiceID = i.InvoiceID 
	WHERE c.CustomerID BETWEEN 2 AND 6
) AS SourceTable
PIVOT (SUM(Qtty)
FOR ShortName IN ([Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT],[Jessie, ND]))
as PVT
ORDER BY InvoiceMonth

--2. ��� ���� �������� � ������, � ������� ���� Tailspin Toys
--������� ��� ������, ������� ���� � �������, � ����� �������
--������ �����������
--CustomerName AddressLine
--Tailspin Toys (Head Office) Shop 38
--Tailspin Toys (Head Office) 1877 Mittal Road
--Tailspin Toys (Head Office) PO Box 8975
--Tailspin Toys (Head Office) Ribeiroville

SELECT CustomerName,
       Addr
FROM (
		SELECT c.CustomerName,
			   c.DeliveryAddressLine1,
			   c.DeliveryAddressLine2,
			   c.PostalAddressLine1,
			   c.PostalAddressLine2
		FROM sales.Customers c
		WHERE c.CustomerName LIKE '%Tailspin Toys%'
	 ) AS SourceTable
UNPIVOT (Addr For Colnname IN (DeliveryAddressLine1,DeliveryAddressLine2,PostalAddressLine1,PostalAddressLine2)) AS Unpvt
ORDER BY CustomerName

--3. � ������� ����� ���� ���� � ����� ������ �������� � ���������
--�������� ������� �� ������, ��������, ��� - ����� � ���� ��� ���� �������� ���� ��������� ���

SELECT CountryID,
	   CountryName,
	   Code
FROM (
		SELECT c.CountryID,
			   c.CountryName,
			   CAST(c.IsoAlpha3Code AS nvarchar) AS IsoAlpha3Code,
			   CAST(c.IsoNumericCode AS nvarchar) AS IsoNumericCode 
		FROM 
		[Application].[Countries] c
	 ) AS SourceTable
UNPIVOT (Code For Colnname IN (IsoAlpha3Code,IsoNumericCode)) AS Unpvt
ORDER BY CountryID

--4. ���������� �� �� ������� ������� ����� CROSS APPLY
--�������� �� ������� ������� 2 ����� ������� ������, ������� �� �������
--� ����������� ������ ���� �� �������, ��� ��������, �� ������, ����, ���� �������

---������ ����� cross apply
SELECT c.CustomerID,
	   c.CustomerName,
	   CR.UnitPrice,
	   CR.InvoiceDate	   
FROM sales.Customers c  
		CROSS APPLY (
					  SELECT TOP 2 il.UnitPrice,
							      max(i.InvoiceDate) AS InvoiceDate  
					  FROM Sales.Invoices i
							join sales.InvoiceLines il 
								ON il.InvoiceID = i.InvoiceID 
					  WHERE c.CustomerID=i.CustomerID
					  GROUP BY il.UnitPrice
					  ORDER BY il.UnitPrice DESC
		             ) AS CR
		
--��� ��������� ������ ����� ������� ������� (������� �������, ��� �������� key lookup ��� �������� ������������ �������, �� �������)	
SELECT CustomerID,
	   CustomerName,
	   UnitPrice,
	   InvoiceDate
FROM (
	   SELECT c.CustomerID,
	   c.CustomerName,
	   s.StockItemID,
	   il.UnitPrice,
	   max(i.InvoiceDate) AS InvoiceDate,
	   row_number () over (partition by c.CustomerID order by il.UnitPrice desc) AS rown_price	   
	   FROM Sales.Invoices i
			JOIN sales.InvoiceLines il
				ON il.InvoiceID = i.InvoiceID 
			JOIN Warehouse.StockItems s
				ON s.StockItemID = il.StockItemID
			JOIN sales.Customers c 
			    ON i.CustomerID=c.CustomerID
group by c.CustomerID,
	     c.CustomerName,
	     s.StockItemID,
	     il.UnitPrice				
		 ) AS x
WHERE rown_price<=2

--5. Code review (�����������). ������ �������� � ��������� Hometask_code_review.sql.

--��� ������ ������ ?
	--������ �� ��������� ������� �� ����� �������� ������ ������� �� ����� , ������� �� ���� �������, � �� ���� �������������
	--�.�. �� ������, �� ������ �������� ������ ����������  ������ ������
	-- �� ��������� �����, ��� ����������� ������ �� ��������������� ��, �.�. ��� ������������ ����� �������� � ������������� ����� �������, ������� ���� [Actual] 0 ��� 1

SELECT     T.FolderId,
		   T.FileVersionId,
		   T.FileId		
	FROM dbo.vwFolderHistoryRemove FHR                     --�����, ������� �������� �����
	CROSS APPLY (SELECT TOP 1   FileVersionId,
								FileId,
								FolderId,
								DirId
		     	FROM #FileVersions V                       -- ��������� ������� �� ����� �������� ������
				WHERE RowNum = 1
					  AND DirVersionId <= FHR.DirVersionId -- ���������, ��� �� ���1 ������� cross apply, �.�. ������� �������� ���, �������� �� DirId � FolderId
				ORDER BY V.DirVersionId DESC) T				
	WHERE FHR.[FolderId] = T.FolderId                      -- ��� ������� ����� ���� �� ������� � cross apply
	AND FHR.DirId = T.DirId								   -- ��� ������� ����� ���� �� ������� � cross apply		
	AND EXISTS (SELECT 1 FROM #FileVersions V WHERE V.DirVersionId <= FHR.DirVersionId) --��� ������� ����� ���� �� ������, �.�. ��� ���� � cross apply
	AND NOT EXISTS (   
			SELECT 1
			FROM dbo.vwFileHistoryRemove DFHR              -- ����� � �������� ��������, ��������, ��� ����� �� �������         
			WHERE DFHR.FileId = T.FileId		         
				AND DFHR.[FolderId] = T.FolderId	     
				AND DFHR.DirVersionId = FHR.DirVersionId 									
			AND NOT EXISTS (
					SELECT 1                              																													
					FROM dbo.vwFileHistoryRestore DFHRes   -- ����� � �������� �������������� ������, �������� ��� ����� �� �������������
					WHERE DFHRes.[FolderId] = T.FolderId                              
						AND DFHRes.FileId = T.FileId
						AND DFHRes.PreviousFileVersionId = DFHR.FileVersionId
					)
			)
--��� ����� �������� CROSS APPLY - ����� �� ������������ ������ ��������� �������\�������?
--� �������� ��� ������, �.�. ��� ������ ������ ������� ��������� ������ ���� ������ �� cross apply