--1. Deaths per year with age info
SELECT *
FROM DeathYear;

--2. Deaths per season (for bar chart over time)
SELECT year, COUNT(*) AS num_deaths, AVG(age) AS avg_age
FROM DeathAge
GROUP BY year
ORDER BY year;

--3. Average difference from mean for birthweight, covariance between birthweights and other weights
SELECT *
FROM LinReg;

--4. AVG weaning, winter, and sale weight
SELECT * FROM BirthWeight;

--5. AVG weaning, winter, and sale weight sorted by birthweight
SELECT birthweight, CAST(AVG(avg_weaning_weight) AS DECIMAL(6, 3)) AS avg_weaning_weight, CAST(AVG(avg_winter_weight) AS DECIMAL(6, 3)) AS avg_winter_weight, CAST(AVG(avg_sale_weight) AS DECIMAL(6, 3)) AS avg_sale_weight
FROM WeightAvg
GROUP BY birthweight
ORDER BY CAST(birthweight AS DECIMAL(4,1));

--6. Weight of every goat (for scatterplot)
SELECT *
FROM WeightType
ORDER BY CAST(birthweight AS DECIMAL(4,1));

--7. Death of every goat by age
SELECT tag, date, age
FROM DeathAge
WHERE year = 2016;

--8. Compare years (total/average)
SELECT A.total_deaths + B.total_deaths AS total_deaths, A.spring + B.spring AS spring, A.summer + B.summer AS summer, A.fall + B.fall AS fall, A.winter + B.winter AS winter
FROM (SELECT * FROM DeathYear WHERE year = 2016) AS A,
    (SELECT * FROM DeathYear WHERE year = 2020) AS B;

--9. Avg birthweight each year
SELECT *
FROM BWperYear;