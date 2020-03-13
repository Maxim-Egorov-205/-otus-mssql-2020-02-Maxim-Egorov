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
	    --����� ������� �������� d 4-� ����� - index scan ������� OrderLines
		--( SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)                               -- ���������� ��������� �� ������ * ���� ������� ���������
		--  FROM Sales.OrderLines
		--  WHERE OrderLines.OrderId = (SELECT Orders.OrderId                                        -- �� ������, ��� ������� ���� �������� ����� � ����� ��� �������������
		--							  FROM Sales.Orders
		--							  WHERE Orders.PickingCompletedWhen IS NOT NULL                --���� ������������ ������ ���������
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
--����� ����������� - ����� 3

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
ORDER BY SUM(ol.PickedQuantity*ol.UnitPrice)  DESC