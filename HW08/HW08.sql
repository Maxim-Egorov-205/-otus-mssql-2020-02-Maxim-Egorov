
/*
1. Напишите запрос с временной таблицей и перепишите его с табличной переменной. Сравните планы.
В качестве запроса с временной таблицей и табличной переменной можно взять свой запрос или следующий запрос:

Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года (в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки)
Выведите id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом
Пример
Дата продажи Нарастающий итог по месяцу
2015-01-29 4801725.31
2015-01-30 4801725.31
2015-01-31 4801725.31
2015-02-01 9626342.98
2015-02-02 9626342.98
2015-02-03 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

--1.1. запрос с временной таблицей
SET STATISTICS TIME ON
--времення таблица с суммой продаж по каждому клиенту по годам и месяцам
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

--Основной запрос
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
--1.2. запрос с табличной переменной
------------------------------------
--табличная переменная с суммой продаж по каждому клиенту по годам и месяцам
SET STATISTICS TIME ON
--табличная переменная с суммой продаж по каждому клиенту по годам и месяцам
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

--основной запрос
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
--итоги:
--планы запросов отличаются
--запрос с табличной переменной тяжелее из-за трех операций в самом конце выполнения  второго запроса (второй план при join с табличной переменной)- index seek, key lookup, index seek
--option recompile ускоряет выполнения запроса с табличной переменной
--время выполнения запроса с табличной переменной будет немного больше , даже если использовать option(recompile)

--2. Если вы брали предложенный выше запрос, то сделайте расчет суммы нарастающим итогом с помощью оконной функции.
--Сравните 2 варианта запроса - через windows function и без них. Написать какой быстрее выполняется, сравнить по set statistics time on;
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
Результаты выполнения запросов:
Временная таблица:	
 Время работы SQL Server:
   Время ЦП = 187 мс, затраченное время = 1049 мс.

Табличная переменная:
 Время работы SQL Server:
   Время ЦП = 1953 мс, затраченное время = 2672 мс.
 
Оконная функция:
 Время работы SQL Server:
   Время ЦП = 282 мс, затраченное время = 1169 мс.	

итоги по скорости выполнения запроса (по убыванию):
	временная таблица
	табличная переменная
	оконная функция

*/

--3. Вывести список 2х самых популярных продуктов (по кол-ву проданных)
-- в каждом месяце за 2016й год (по 2 самых популярных продукта в каждом месяце)

---заполняем табличное выражение 
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
--итоговый select из табличного выражения
SELECT y,
	   m,
       StockItemName
FROM CTE_TOP2
WHERE rown<=2
order by y,
	     m,
		 rown desc

/*
4. Функции одним запросом
Посчитайте по таблице товаров, в вывод также должен попасть ид товара, название, брэнд и цена
пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
посчитайте общее количество товаров и выведете полем в этом же запросе
посчитайте общее количество товаров в зависимости от первой буквы названия товара
отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
предыдущий ид товара с тем же порядком отображения (по имени)
названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"

сформируйте 30 групп товаров по полю вес товара на 1 шт
Для этой задачи НЕ нужно писать аналог без аналитических функций
*/

SELECT s.StockItemID, 
	   s.StockItemName,
	   s.Brand,
	   s.UnitPrice,
	   ROW_NUMBER () OVER (PARTITION BY LEFT(s.StockItemName,1) ORDER BY LEFT(s.StockItemName,1)) AS Rown_name,    --пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново     
	   COUNT(s.StockItemID)  OVER () AS All_Qtty, --общее количество товаров
	   COUNT(s.StockItemID)  OVER (PARTITION BY LEFT(s.StockItemName,1)) AS First_Symb_Qtty, --общее количество товаров в зависимости от первой буквы названия товара
	   LEAD(s.StockItemID) over (ORDER BY s.StockItemName) AS Next_ID, --следующий id товара
	   LAG(s.StockItemID) over (ORDER BY s.StockItemName) AS Prev_ID, --предыдущий id товара
	   ISNULL(LAG(s.StockItemName,2) over (ORDER BY s.StockItemName),'No items') AS Prev_Two_Symb_ID, --предыдущий id товара 2 строки назад
	   NTILE(30)  OVER (ORDER BY s.TypicalWeightPerUnit) AS Group_per_weight, --30 групп товаров по полю вес товара на 1 шт
	   s.TypicalWeightPerUnit
FROM Warehouse.StockItems s
order by s.TypicalWeightPerUnit

--5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал
--В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки
SELECT PersonID,
	   LastName, 
	   CustomerID,
       CustomerName,
	   InvoiceDate,
	   SumSale
FROM
(
	SELECT p.PersonID,
		   SUBSTRING(p.FullName,CHARINDEX(' ',p.FullName),LEN(p.FullName)) AS LastName, --фамилия сотрудника
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


--6. Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
--В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки

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