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
FROM sales.Invoices i
	JOIN Sales.InvoiceLines il
		ON i.InvoiceID=il.InvoiceID              
	JOIN CteMaxUnitPrice m
		ON il.StockItemID = m.StockItemID     
	JOIN Sales.Customers c
		ON  i.CustomerID=c.CustomerID
	JOIN Application.Cities ct 
		ON  c.DeliveryCityID=ct.CityId  	    
    JOIN Application.People	p
		ON i.PackedByPersonID=p.PersonID    
		 		 	                                    											
--4.2. �����������
SELECT DISTINCT ct.CityID,
		        ct.CityName,
		        p.FullName	 
FROM sales.Invoices i
	JOIN Sales.InvoiceLines il
		ON i.InvoiceID=il.InvoiceID                
	JOIN Sales.Customers c
		ON  i.CustomerID=c.CustomerID
	JOIN Application.Cities ct 
		ON  c.DeliveryCityID=ct.CityId  	    
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
		WHERE il.StockItemID = m.StockItemID
	)

--5. ���������, ��� ������ � ������������� ������:
--��������� ���� ������� � ��� ������, � ����� ��� ����� ����������� �� ������ �����������.
SELECT Invoices.InvoiceID,
	   Invoices.InvoiceDate,
		(
		  SELECT People.FullName
		  FROM Application.People
		  WHERE people.PersonID = Invoices.SalespersonPersonID
		) AS SalesPersonName,
		SalesTotals.TotalSumm AS TotalSummByInvoice,
		( SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)                               -- ���������� ��������� �� ������ * ���� ������� ���������
		  FROM Sales.OrderLines
		  WHERE OrderLines.OrderId = (SELECT Orders.OrderId                                        -- �� ������, ��� ������� ���� �������� ����� � ����� ��� �������������
									  FROM Sales.Orders
									  WHERE Orders.PickingCompletedWhen IS NOT NULL                --���� ������������ ������ ���������
										AND Orders.OrderId = Invoices.OrderId)
		) AS TotalSummForPickedItems
FROM Sales.Invoices
	JOIN (
		  SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
		  FROM Sales.InvoiceLines
		  GROUP BY InvoiceId
		  HAVING SUM(Quantity*UnitPrice) > 27000
		  ) AS SalesTotals	
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

--����������:
-- ��� ������, ����� ������� ������ 27 000 ��������
-- ������� id �����
-- ���� �����
-- ��� ��������, ����������� ����
-- �������� ����� �����
-- �������� ����� ������� ���������������� ����� ����������������� ������ (���� ������������ ��������� - �� ����)

--������ ����� ������� (������� ����� ������ ����, ����� 5 �����)
--1. index scan ������� People, ��������� ���������
		--������������� ���������� 
		--(
		--  SELECT People.FullName
		--  FROM Application.People
		--  WHERE people.PersonID = Invoices.SalespersonPersonID
		--) AS SalesPersonName,

--2. index scan ������� InvoicesLines ��������� ���������, 
          --������������� ���������� 
		  --SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
		  --FROM Sales.InvoiceLines
		  --GROUP BY InvoiceId
		  --HAVING SUM(Quantity*UnitPrice) > 27000

--3. index scan ������� Invoices, ��������� ��������� , ����� Invoices � ����������� �� �.2.
--FROM Sales.Invoices
--	JOIN (
--		  SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
--		  FROM Sales.InvoiceLines
--		  GROUP BY InvoiceId
--		  HAVING SUM(Quantity*UnitPrice) > 27000
--		  ) AS SalesTotals	
--		ON Invoices.InvoiceID = SalesTotals.InvoiceID


--4 � 5-� �����.
	    --����� ������� �������� � 4-� ����� - index scan ������� OrderLines
		--( SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)                               -- ���������� ��������� �� ������ * ���� ������� ���������
		--  FROM Sales.OrderLines
		--  WHERE OrderLines.OrderId = (SELECT Orders.OrderId                                        -- �� ������, ��� ������� ���� �������� ����� � ����� ��� �������������
		--							  FROM Sales.Orders
		--							  WHERE Orders.PickingCompletedWhen IS NOT NULL                   --���� ������������ ������ ���������
		--								AND Orders.OrderId = Invoices.OrderId)
		--) AS TotalSummForPickedItems


--��� ����������� �� ������ �����������:
--���������� ����� - ������� indexscan 4-� �����, ����� ���� ������ ����������� ������������� ������� �� ������� OrderLines �� ��� ����, ��������� � ����� �������.
--�� ��������� ������ ��� ������� ������� - ����� �� ����� �� ������, ������� ���� ����������� ���������� ������,
--�.�. �������� ��������, �� ��� ������ - ������ ������������� � ������ ������������� ��������� �����������

--���������������� ������
--���������� ���� �������� � ��������� CTE (��� ��� �������� ������, ��� � ��� ���������� �� �����������)
--������ ��� ��������� ���, ����� �� ���� ��������� �����������, �������� ����� ������ ��� ������ ������ �������� �������
--���� ���������, ���  SQL server ��������� ������ � ���� �����������, � ����� ������ ��� �� ���������

--�� ����������� ��������� ���� ����� 9
--����� ����������� - ����� 3,8

WITH CteSalesTotals AS -- ��� �����, ����� ������� ������ 27 000 ��������
(
	SELECT il.InvoiceId,
	       SUM(il.Quantity*il.UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines il
	GROUP BY il.InvoiceId
	HAVING SUM(il.Quantity*il.UnitPrice) > 27000
),
CteSalesPersonName AS --��� �������� ���������� ����� ������ 27000
(
	SELECT i.InvoiceID,
		   p.PersonID,
		   p.FullName as SalesPersonName	 
	FROM Sales.Invoices i
		JOIN CteSalesTotals ct1 
			ON i.InvoiceID=ct1.InvoiceID
		JOIN Application.people p 
			ON p.PersonID = i.SalespersonPersonID
)
SELECT i.InvoiceID,
	   i.InvoiceDate,
	   ct2.SalesPersonName,
	   ct1.TotalSumm,
	   SUM(ol.PickedQuantity*ol.UnitPrice)   AS TotalSummForPickedItems	
FROM Sales.Invoices i
	JOIN CteSalesTotals ct1
		 ON i.InvoiceID =ct1.InvoiceID
	JOIN CteSalesPersonName ct2 
		ON i.InvoiceID=ct2.invoiceid
	JOIN Sales.OrderLines ol 
		ON ol.OrderID=i.OrderID
GROUP BY i.InvoiceID,
	     i.InvoiceDate,
	     i.OrderID,
	     ct2.SalesPersonName,
	     ct1.TotalSumm
ORDER BY TotalSummForPickedItems	  DESC


--6. ������������ �����:
--� ���������� � �������� ���� ���� HT_reviewBigCTE.sql - �������� ���� ������ � �������� ��� �� ������ ������� � � ��� ��� �����, ����� ���� ���� ���� �� ��������� ���� �� ��������.

--�����
--�� ���� ����� ������� ���������� ������� ������ ���� ��������� ����������
--    @DFBatchSize               ������ ������   
--	  @vfId                      id ����������� �����
--	  @vfOwnerId                 �������� ����������� �����
--	  @maxDFKeepDate             ������������ ���� ��������?
--	  @keepDeletedFromDate       ������� ����� ��������

-----------------------------------------
--��������� ������� #companyCustomRules T
-----------------------------------------
--���� �������:
--DeletedFileYears,  ��������� ����� �� ���        
--DeletedFileMonths, ��������� ����� �� �����
--DeletedFileDays    ��������� ����� �� ����
--CustomRuleId       id ����������������� �������  
--Priority           ���������
--RuleType           ��� �������
--RuleCondition      ������� ������������ �������
--RuleItemFileType   ������� �������� ���� ����� ???
--RuleItemFileMask   ������� �������� ����� ����� 

------------------------------------
--���������� ������� dbo.UserFile DF -- ����� ������������
------------------------------------
--FolderId    -- id �����
--UserFileId  -- id ����� ������������
--ExtensionId -- id ���������� �����  

------------------------------------------
--���������� ������� dbo.UserFileExtension dfe --���������� ���������� ���������������� ������ 
------------------------------------------
--dfe.[ExtensionId] --  id ���������� ���������������� ������
--dfe.[FileTypeId]  --  id ���� �����

-----------------------------------------------------
--������������ ������� dbo.RegExMatch(DF.Name, T.RuleItemFileMask) 
------------------------------------------------------

---------------------------------------------------
--������������ ������������� dbo.vwUserFileInActive  
---------------------------------------------------

-- � ��� ����� �������?
-- ��� �����������

-- ������ CTE: �� id ����������� ����� ������� ����� ��������� ����������� �����: � �����, ������������ � �.�.
-- ��� ����������� ���� �������� ������ ������������ ���� ��������, �.�. ������ ����� � ��������� "������", �� ��� ���������� � �������� "�������".

-- ������ CTE: 
-- ����� exists ����������� ������ � ������������ � 8-� ��������� (8 union all) �� ���� 8 ������� ������� OR

-- ���� �� �����������
-- �� ������ ����� Cross join ����� ���� ������� �������, � ������� #companyCustomRules? ��� �������, 8 �������.
-- ���� ������ CTE ������ 1000 �������, ����� cross join ������� ��� 8000. 
-- �� ���� ���� �� �� �������� ������ ���� ��������� CTE ������� �� CROSS joina, � ����������� ������ ������� �������� ����.
-- ����� ������� ������ ����� ���� � ����������� �� 8-�� �������, ������ ������ ���� � exists, � ���-�� ���� ����� ������ ��������� ����� 
-- ��������� ������� #companyCustomRules � ������ CTE � �������� ���������, ����� �� ����� ������� CROSS JOIN � �������
-- ����� ������� ������ �� ��������������� ������� CTE

WITH cteDeletedDF as
(
SELECT top (@DFBatchSize)                                    -- ������ ������
		df.UserFileId,                                       -- id ���� ������������
		@vfId as VirtualFolderId,                            -- id ����������� �����
		@vfOwnerId as OwnerId,                               -- �������� ����������� ������
		df.UserFileVersionId,                                -- id ������ ����� ������������ 
		df.FileId,                                           -- id ���� 
		df.[Length],                                         -- ����� (���� - �� �������)
		df.EffectiveDateRemovedUtc as lastDeleteDate,        -- ��������� ����������� ���� �������� � ������� utc
		@vfFolderId as FolderId                              -- id �����
 FROM dbo.vwUserFileInActive df with(nolock)                 -- �������������
  WHERE df.[FolderId] = @vfFolderId                          -- id ����������� ����� 
	AND df.EffectiveDateRemovedUtc < @maxDFKeepDate          -- ����������� ���� �������� < ���� ���� ��������
),

cteDeletedDFMatchedRules
as
(
SELECT ROW_NUMBER() over(partition by DF.UserFileId order by T.Priority) rn,
		DATEADD(YEAR, -t.DeletedFileYears,
				DATEADD(MONTH, -t.DeletedFileMonths,
						DATEADD(DAY, -t.DeletedFileDays , @keepDeletedFromDate))) customRuleKeepDate,
		T.DeletedFileDays as customDeletedDays,
		T.DeletedFileMonths as customDeletedMonths,
		T.DeletedFileYears as customDeletedYears,
		T.CustomRuleId,                   
		dDf.UserFileId,               -- id ����������������� �����
		dDF.FolderId as FolderId      -- id �����
FROM cteDeletedDF dDF
INNER JOIN dbo.UserFile DF with(nolock) on dDF.FolderId = df.FolderId and dDF.UserFileId = Df.UserFileId
LEFT JOIN dbo.UserFileExtension dfe with(nolock) on df.[ExtensionId] = dfe.[ExtensionId]
CROSS JOIN #companyCustomRules T
WHERE
  (
	EXISTS
		(
		SELECT TOP 1
				1 as id
		 where T.RuleType = 0
			and T.RuleCondition = 0
			and T.RuleItemFileType = dfe.[FileTypeId]

		 union all

		SELECT TOP 1
				1
		 where T.RuleType = 0
			and T.RuleCondition = 1
			and T.RuleItemFileType <> dfe.[FileTypeId]

		union all

		SELECT TOP 1
				1
		 where T.RuleType = 1
			and T.RuleCondition = 0
			and DF.Name = T.RuleItemFileMask

		union all

		SELECT TOP 1
				1
		 where T.RuleType = 1
			and T.RuleCondition = 4
			and DF.Name like  case T.RuleCondition
							  when 4
							  then '%' + T.RuleItemFileMask + '%' --never will be indexed
							  when 3
							  then '%' + T.RuleItemFileMask --never will be indexed
							  when 2
							  then T.RuleItemFileMask + '%' --may be indexed
							 end

		union all

		SELECT TOP 1
				1
		 where T.RuleType = 1
			and T.RuleCondition = 5
			and dbo.RegExMatch(DF.Name, T.RuleItemFileMask) = 1 --never will be indexed

		union all

		SELECT TOP 1
				1
		 where T.RuleType = 2
			and T.RuleCondition = 6
			and DF.[Length] > T.RuleItemFileSize

		union all

		SELECT TOP 1
				1
		 where T.RuleType = 2
			and T.RuleCondition = 7
			and DF.[Length] < T.RuleItemFileSize

		union all

		SELECT TOP 1
				1
		 where T.RuleType = 3
			and T.RuleCondition = 0
			and dDF.VirtualFolderId = T.RuleItemVirtualFolderId

		union all

		SELECT TOP 1
				1
		 where T.RuleType = 3
			and T.RuleCondition = 8
			and T.RuleItemVirtualFolderOwnerId = dDf.OwnerId
		)
  )
)


