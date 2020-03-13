--1. ¬ыберите сотрудников, которые €вл€ютс€ продажниками, и еще не сделали ни одной продажи.
--1.1.через вложенный запрос
SELECT p.PersonID,
	   p.FullName
FROM [Application].[People] p
WHERE  NOT EXISTS (SELECT o.SalespersonPersonID  FROM SALES.ORDERS o WHERE p.PersonID=o.SalespersonPersonID)
   AND p.IsSalesperson=1 --продажники

--1.2.через WITH (дл€ производных таблиц)
WITH CteSalesPersonOrders AS                                            --все id продажников, которые создавали заказы
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
	AND p.IsSalesperson=1 --продажники

--2. ¬ыберите товары с минимальной ценой (подзапросом), 2 варианта подзапроса.
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

--2.3.через WITH (дл€ производных таблиц)
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

--3. ¬ыберите информацию по клиентам, которые перевели компании 5 максимальных
--платежей из [Sales].[CustomerTransactions] представьте 3 способа (в том числе с CTE)
--3.1 c CTE
WITH CteMaxTransactionAmount AS              --5 максимальных платежей  клиентов 
(
	SELECT TOP 5 CustomerID
	FROM [Sales].[CustomerTransactions] 
	ORDER BY TransactionAmount DESC
)
SELECT DISTINCT c.CustomerID,
			    c.CustomerName
FROM Sales.Customers c
	JOIN CteMaxTransactionAmount ct ON c.CustomerID=ct.CustomerID

--3.2 ¬ариант с IN
SELECT c.CustomerID,
	   c.CustomerName
FROM Sales.Customers c
WHERE c.CustomerID IN 
	(
	SELECT TOP 5 CustomerID
	FROM [Sales].[CustomerTransactions] 
	ORDER BY TransactionAmount DESC
	)

--3.3 вариант с cte,exists
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

--4. ¬ыберите города (ид и название), в которые были доставлены товары,
--вход€щие в тройку самых дорогих товаров, а также »м€ сотрудника, который осуществл€л упаковку заказов
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
--4.2. подзапросом
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