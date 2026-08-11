USE chinook;

-- Top 5 Artists In Terms of Sales:
SELECT ar.Name AS Artist_Name,
	SUM(il.UnitPrice * il.Quantity) AS Total_Revenue
FROM artist ar
JOIN album al ON ar.ArtistId = al.ArtistId
JOIN track t ON al.AlbumId = t.AlbumId
JOIN invoiceline il ON t.TrackId = il.TrackId
GROUP BY ar.ArtistId, ar.Name
ORDER BY Total_Revenue DESC
LIMIT 5;

-- Artists & Their Monthly Total Revenue and Running Total:
SELECT ar.Name AS Artist_Name,
	DATE_FORMAT (i.InvoiceDate, '%Y-%M') AS Month,
	SUM(il.UnitPrice * il.Quantity) AS Monthly_Revenue,
    SUM(SUM(il.UnitPrice * il.Quantity))
		OVER (PARTITION BY ar.Name
			ORDER BY DATE_FORMAT(i.InvoiceDate, '%Y-%M')) AS Running_Total
FROM artist ar
JOIN album al ON ar.ArtistId = al.ArtistId
JOIN track t ON al.AlbumId = t.AlbumId
JOIN invoiceline il ON t.TrackId = il.TrackId
JOIN invoice i ON il.InvoiceId = i.InvoiceId
GROUP BY ar.Name, DATE_FORMAT(i.InvoiceDate, '%Y-%M')
ORDER BY ar.Name, Month;

-- For Each Album, What Track Generated The Most Revenue & What Percentage of Total Album Revenue Did It Bring In?
SELECT al.Title AS Album_Name, t.Name AS Track_Name,
	SUM(il.UnitPrice * il.Quantity) AS Track_Revenue,
    SUM(SUM(il.UnitPrice * il.Quantity))
		OVER (PARTITION BY al.AlbumId) AS Album_Revenue,
	 ROUND(SUM(il.UnitPrice * il.Quantity) / 
		SUM(SUM(il.UnitPrice * il.Quantity))
        OVER (PARTITION BY al.AlbumId) * 100, 2)
	AS Percentage
FROM album al
JOIN track t ON al.AlbumId = t.AlbumId
JOIN invoiceline il ON t.TrackId = il.TrackId
GROUP BY al.AlbumId, al.Title, t.TrackId, t.Name
ORDER BY al.Title, Track_Revenue DESC;

-- Artists Whose Monthly Revenue Dropped Compared To The Previous Month:
WITH Monthly_Revenue AS (
	SELECT
		ar.Name AS Artist_Name,
		DATE_FORMAT(i.InvoiceDate, '%Y-%M') AS Month,
		SUM(il.UnitPrice * il.Quantity) AS Revenue
	FROM artist ar
    JOIN album al ON ar.ArtistId = al.ArtistId
	JOIN track t ON al.AlbumId = t.AlbumId
    JOIN invoiceline il ON t.TrackId = il.TrackId
	JOIN invoice i ON il.InvoiceId = i.InvoiceId
	GROUP BY ar.Name, DATE_FORMAT(i.InvoiceDate, '%Y-%M')
),
Lagged AS (
	SELECT
		Artist_Name,
		Month,
		Revenue,
		LAG(Revenue) OVER (PARTITION BY Artist_Name
						ORDER BY Month) AS Previous_Month_Revenue
	FROM Monthly_Revenue
)
SELECT *
FROM Lagged
WHERE Revenue < Previous_Month_Revenue
ORDER BY Artist_Name, Month;

-- Top-Selling Artist For Each Genre Based On Total Revenue:
WITH Genre_Artist_Revenue AS (
	SELECT
		g.Name AS Genre,
        ar.Name AS Artist_Name,
		SUM(il.UnitPrice * il.Quantity) AS Total_Revenue
	FROM genre g
	JOIN track t ON g.GenreId = t.GenreId
    JOIN invoiceline il ON t.TrackId = il.TrackId
	JOIN album al ON t.AlbumId = al.AlbumId
    JOIN artist ar ON al.ArtistId = ar.ArtistId
	GROUP BY g.Name, ar.Name
),
Ranked AS (
	SELECT
		Genre,
        Artist_Name,
		Total_Revenue,
		RANK() OVER (PARTITION BY Genre
						ORDER BY Total_Revenue DESC) AS Rank_Num
	FROM Genre_Artist_Revenue
)
SELECT
	Genre,
    Artist_Name,
    Total_Revenue
FROM Ranked
WHERE Rank_Num = 1
ORDER BY Total_Revenue DESC;