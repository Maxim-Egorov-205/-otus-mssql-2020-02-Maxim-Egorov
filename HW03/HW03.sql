--1. Выберите сотрудников, которые являются продажниками, и еще не сделали ни одной продажи.
--1.1.через вложенный запрос
SELECT p.PersonID,
	   p.FullName
FROM [Application].[People] p
WHERE  NOT EXISTS (SELECT SalespersonPersonID --все id продажников, которые создавали заказы
	FROM SALES.ORDERS)
   AND p.IsSalesperson=1 --продажники

--1.2.через WITH (для производных таблиц)
WITH CteSalesPersonOrders AS              --все id продажников, которые создавали заказы
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

--2. Выберите товары с минимальной ценой (подзапросом), 2 варианта подзапроса.
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

--2.3.через WITH (для производных таблиц)
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

--3. Выберите информацию по клиентам, которые перевели компании 5 максимальных
--платежей из [Sales].[CustomerTransactions] представьте 3 способа (в том числе с CTE)
--3.1 c CTE
WITH CteMaxTransactionAmount AS              --5 максимальных платежей  клиентов (на всякий случай берем разных клиентов,т.к. может быть всего один клиент, сделавших 5 максимальных платежей)
(
	SELECT TOP 5 CustomerID
	FROM [Sales].[CustomerTransactions] 
	GROUP BY CustomerID
	ORDER BY MAX(TransactionAmount) DESC
)
SELECT c.CustomerID,
	   c.CustomerName
FROM Sales.Customers c
	JOIN CteMaxTransactionAmount ct ON c.CustomerID=ct.CustomerID

--3.2 Вариант с IN
SELECT c.CustomerID,
	   c.CustomerName
FROM Sales.Customers c
WHERE c.CustomerID IN 
	(
	SELECT TOP 5 CustomerID
	FROM [Sales].[CustomerTransactions] 
	GROUP BY CustomerID
	ORDER BY MAX(TransactionAmount) DESC
	)

--3.3 вариант с cte,exists
WITH CteMaxTransactionAmount AS             
(
	SELECT TOP 5 CustomerID
	FROM [Sales].[CustomerTransactions] 
	GROUP BY CustomerID
	ORDER BY MAX(TransactionAmount) DESC
)
SELECT c.CustomerID,
	   c.CustomerName
FROM Sales.Customers c
WHERE EXISTS (SELECT CustomerID FROM CteMaxTransactionAmount ct where ct.CustomerID=c.CustomerID) 
