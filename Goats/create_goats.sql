/*
Creates our tables and views
Primary Source Code writer: Michael
Last updated: 4/25/24
*/
DROP VIEW DeathYear;
DROP VIEW DeathAge;
DROP VIEW BirthWeight;
DROP VIEW WeightAvg;
DROP VIEW WeightType;
DROP VIEW WeaningWeight;
DROP VIEW WinterWeight;
DROP VIEW SaleWeight;
DROP VIEW LinReg;
DROP VIEW DeathSpring;
DROP VIEW DeathSummer;
DROP VIEW DeathFall;
DROP VIEW DeathWinter;
DROP VIEW BWperYear;

DROP TABLE Goat;
CREATE TABLE Goat (
    goat_id integer PRIMARY KEY,
    goat_tag varchar(16),
    birthdate timestamp,
    birthweight varchar(20),
    last_weight varchar(20),
    last_weight_date timestamp,
    goat_status varchar(20));

DROP TABLE Weight;
CREATE TABLE Weight (
    session integer,
    goat_id integer,
    trait integer,
    w_date timestamp,
    alpha_value varchar(20),
    primary key(session, goat_id, trait, w_date));

DROP TABLE Death;
CREATE TABLE Death (
    goat_id integer PRIMARY KEY,
    goat_tag varchar(16),
    d_date timestamp);

INSERT INTO Goat (goat_id, goat_tag, birthdate, birthweight, last_weight, last_weight_date, goat_status)
SELECT Animal.animal_id, Animal.tag, Animal.dob, MIN(SessionAnimalTrait.alpha_value) AS birthweight, Animal.last_weight, Animal.last_weight_date, Animal.status
FROM Animal LEFT JOIN SessionAnimalTrait ON Animal.animal_id = SessionAnimalTrait.animal_id
AND SessionAnimalTrait.trait_code = 357 AND SessionAnimalTrait.alpha_value != '0' AND SessionAnimalTrait.alpha_value != ''
GROUP BY 
    Animal.animal_id, 
    Animal.dob, 
    Animal.last_weight, 
    Animal.last_weight_date, 
    Animal.status;

INSERT INTO Weight (session, goat_id, trait, w_date, alpha_value)
SELECT session_id, animal_id, trait_code, when_measured, alpha_value
FROM SessionAnimalTrait
WHERE trait_code IN (53, 369, 381, 393, 405, 436, 448, 963, 970)
AND alpha_value != '0' AND alpha_value != '';

INSERT INTO Death (goat_id, goat_tag, d_date)
SELECT animal_id, tag, status_date
FROM Animal
WHERE status = 'Dead';

CREATE VIEW DeathSpring AS
SELECT goat_tag AS tag, EXTRACT(YEAR FROM Death.d_date) AS year, EXTRACT(MONTH FROM Death.d_date) AS month
FROM Death
WHERE EXTRACT(MONTH FROM Death.d_date) IN (2, 3, 4);

CREATE VIEW DeathSummer AS
SELECT goat_tag AS tag, EXTRACT(YEAR FROM Death.d_date) AS year, EXTRACT(MONTH FROM Death.d_date) AS month
FROM Death
WHERE EXTRACT(MONTH FROM Death.d_date) IN (5, 6, 7);

CREATE VIEW DeathFall AS
SELECT goat_tag AS tag, EXTRACT(YEAR FROM Death.d_date) AS year, EXTRACT(MONTH FROM Death.d_date) AS month
FROM Death
WHERE EXTRACT(MONTH FROM Death.d_date) IN (8, 9, 10);

CREATE VIEW DeathWinter AS
SELECT goat_tag AS tag, EXTRACT(YEAR FROM Death.d_date) AS year, EXTRACT(MONTH FROM Death.d_date) AS month
FROM Death
WHERE EXTRACT(MONTH FROM Death.d_date) IN (11, 12, 1);

CREATE VIEW DeathYear AS
WITH Total AS (
	SELECT COUNT(*) AS total_deaths, EXTRACT(YEAR FROM Death.d_date) AS year
    FROM Death
    GROUP BY year),
Spring AS (
    SELECT COUNT(*) AS spring, EXTRACT(YEAR FROM Death.d_date) AS year
    FROM Death
    WHERE EXTRACT(MONTH FROM Death.d_date) IN (2, 3, 4)
    GROUP BY year),
Summer AS (
    SELECT COUNT(*) AS summer, EXTRACT(YEAR FROM Death.d_date) AS year
    FROM Death
    WHERE EXTRACT(MONTH FROM Death.d_date) IN (5, 6, 7)
    GROUP BY year),
Fall AS (
    SELECT COUNT(*) AS fall, EXTRACT(YEAR FROM Death.d_date) AS year
    FROM Death
    WHERE EXTRACT(MONTH FROM Death.d_date) IN (8, 9, 10)
    GROUP BY year),
Winter AS (
    SELECT COUNT(*) AS winter, EXTRACT(YEAR FROM Death.d_date) AS year
    FROM Death
    WHERE EXTRACT(MONTH FROM Death.d_date) IN (1, 11, 12)
    GROUP BY year)
SELECT Total.year, Total.total_deaths, Spring.spring, Summer.summer, Fall.fall, Winter.winter
FROM Total LEFT JOIN Spring ON Total.year = Spring.year LEFT JOIN Summer ON Total.year = Summer.year LEFT JOIN Fall ON Total.year = Fall.year LEFT JOIN Winter ON Total.year = Winter.year
ORDER BY Total.year;

CREATE VIEW DeathAge AS
SELECT EXTRACT(YEAR FROM Death.d_date) AS year, Goat.goat_tag AS tag, Death.d_date AS date, AGE(Death.d_date, Goat.birthdate) AS age
FROM Goat JOIN Death ON Goat.goat_id = Death.goat_id
ORDER BY Death.d_date;

--NEED TO CHANGE SO ONLY 1 WEANING AND SALE WEIGHT PER GOAT (multiple winter weights messes up join)
CREATE VIEW WeightType AS
WITH Weaning AS (
    SELECT Goat.goat_id as goat_id, CAST(COALESCE(NULLIF(Weight.alpha_value, ''), '0') AS DECIMAL(4,1)) AS weaning_weight
    FROM Weight JOIN Goat ON Weight.goat_id = Goat.goat_id
    WHERE EXTRACT(YEAR FROM(AGE(Weight.w_date, Goat.birthdate))) = 0 AND EXTRACT(MONTH FROM(Weight.w_date)) IN (8, 9)
    AND CAST(Goat.birthweight AS DECIMAL(4,1)) BETWEEN 1 AND 25),
Winter AS (
    SELECT Goat.goat_id as goat_id, CAST(COALESCE(NULLIF(Weight.alpha_value, ''), '0') AS DECIMAL(4,1)) AS winter_weight
    FROM Weight JOIN Goat ON Weight.goat_id = Goat.goat_id
    WHERE EXTRACT(MONTH FROM Weight.w_date) IN (1, 11, 12)
    AND CAST(Goat.birthweight AS DECIMAL(4,1)) BETWEEN 1 AND 25),
Sale AS (
    SELECT Goat.goat_id as goat_id, CAST(COALESCE(NULLIF(Goat.last_weight, ''), '0') AS DECIMAL(4,1)) AS sale_weight
    FROM Goat
    WHERE goat_status = 'Sold'
    AND CAST(Goat.birthweight AS DECIMAL(4,1)) BETWEEN 1 AND 25)
SELECT Goat.goat_tag as tag, Goat.birthweight, Weaning.weaning_weight, Winter.winter_weight, Sale.sale_weight
FROM Goat LEFT JOIN Weaning ON Goat.goat_id = Weaning.goat_id LEFT JOIN Winter ON Goat.goat_id = Winter.goat_id LEFT JOIN Sale ON Goat.goat_id = Sale.goat_id
WHERE Weaning.weaning_weight IS NOT NULL OR Winter.winter_weight IS NOT NULL OR Sale.sale_weight IS NOT NULL;

CREATE VIEW WeaningWeight AS
WITH Weaning AS (
    SELECT Goat.goat_id as goat_id, CAST(COALESCE(NULLIF(Weight.alpha_value, ''), '0') AS DECIMAL(4,1)) AS weaning_weight
    FROM Weight JOIN Goat ON Weight.goat_id = Goat.goat_id
    WHERE EXTRACT(YEAR FROM(AGE(Weight.w_date, Goat.birthdate))) = 0 AND EXTRACT(MONTH FROM(Weight.w_date)) IN (8, 9)
    AND CAST(Goat.birthweight AS DECIMAL(4,1)) BETWEEN 1 AND 25)
SELECT Goat.goat_id AS goat_id, Goat.goat_tag as goat_tag, Goat.birthweight as birthweight, Weaning.weaning_weight as weaning_weight
FROM Goat LEFT JOIN Weaning ON Goat.goat_id = Weaning.goat_id
WHERE Weaning.weaning_weight != 0;

CREATE VIEW WinterWeight AS
WITH Winter AS (
    SELECT Goat.goat_id as goat_id, CAST(COALESCE(NULLIF(Weight.alpha_value, ''), '0') AS DECIMAL(4,1)) AS winter_weight
    FROM Weight JOIN Goat ON Weight.goat_id = Goat.goat_id
    WHERE EXTRACT(MONTH FROM Weight.w_date) IN (1, 11, 12)
    AND CAST(Goat.birthweight AS DECIMAL(4,1)) BETWEEN 1 AND 25)
SELECT Goat.goat_id AS goat_id, Goat.goat_tag AS tag, Goat.birthweight AS birthweight, Winter.winter_weight AS winter_weight
FROM Goat LEFT JOIN Winter ON Goat.goat_id = Winter.goat_id
WHERE Winter.winter_weight != 0;

CREATE VIEW SaleWeight AS
WITH Sale AS (
    SELECT Goat.goat_id as goat_id, CAST(COALESCE(NULLIF(Goat.last_weight, ''), '0') AS DECIMAL(4,1)) AS sale_weight
    FROM Goat
    WHERE goat_status = 'Sold'
    AND CAST(Goat.birthweight AS DECIMAL(4,1)) BETWEEN 1 AND 25)
SELECT Goat.goat_id AS goat_id, Goat.goat_tag AS tag, Goat.birthweight AS birthweight, Sale.sale_weight AS sale_weight
FROM Goat LEFT JOIN Sale ON Goat.goat_id = Sale.goat_id
WHERE Sale.sale_weight != 0;

CREATE VIEW BirthWeight AS
SELECT Goat.birthweight, CAST(AVG(WeaningWeight.weaning_weight) AS DECIMAL(6,3)) AS avg_weaning, CAST(AVG(WinterWeight.winter_weight) AS DECIMAL(6,3)) AS avg_winter, CAST(AVG(SaleWeight.sale_weight) AS DECIMAL(6,3)) AS avg_sale
FROM Goat LEFT JOIN WeaningWeight ON Goat.goat_id = WeaningWeight.goat_id LEFT JOIN WinterWeight ON Goat.goat_id = WinterWeight.goat_id LEFT JOIN SaleWeight ON Goat.goat_id = SaleWeight.goat_id
WHERE CAST(Goat.birthweight AS DECIMAL(4,1)) BETWEEN 1 AND 25
AND (WeaningWeight.weaning_weight IS NOT NULL OR WinterWeight.winter_weight IS NOT NULL OR SaleWeight.sale_weight IS NOT NULL)
GROUP BY Goat.birthweight
ORDER BY CAST(Goat.birthweight AS DECIMAL(4,1));

CREATE VIEW WeightAvg AS
SELECT CAST(birthweight AS DECIMAL(4,1)) AS birthweight, AVG(weaning_weight) AS avg_weaning_weight, AVG(winter_weight) AS avg_winter_weight, AVG(sale_weight) AS avg_sale_weight
FROM WeightType
GROUP BY birthweight
ORDER BY CAST(birthweight AS DECIMAL(4,1));

--Linear regression: variance and covaraince. Slope and intercept to be calculated on site
--Slope = cov / var
--ie. slope for weaning line = cov_weaning_weight / var_birthweight (var_birthweight is the var for all of them)
--Intercept = avgY - (slope * avgX)
--ie. intercept for weaning line = avg_weaning_weight - (slope_weaning * avg_birthweight)
--All averages needed are calculated in query 4
CREATE VIEW LinReg AS
WITH Variance AS (
    SELECT SUM(diffsqr) / (COUNT(*) - 1) AS var_birthweight
    FROM (
        SELECT POWER(CAST(birthweight AS DECIMAL(4,1)) - (SELECT AVG(CAST(birthweight AS DECIMAL(4,1))) FROM Goat), 2) AS diffsqr
        FROM Goat
        WHERE CAST(birthweight AS DECIMAL(4,1)) BETWEEN 1 AND 25)),
CovarianceWeaning AS (
    SELECT SUM((CAST(Goat.birthweight AS DECIMAL(4,1)) - (SELECT AVG(CAST(Goat.birthweight AS DECIMAL(4,1))) FROM Goat))
        * (CAST(Weight.alpha_value AS DECIMAL(4,1)) - (SELECT AVG(CAST(Weight.alpha_value AS DECIMAL(4,1))) FROM Weight JOIN Goat ON Weight.goat_id = Goat.goat_id
        WHERE EXTRACT(YEAR FROM(AGE(Weight.w_date, Goat.birthdate))) = 0 AND EXTRACT(MONTH FROM(Weight.w_date)) IN (8, 9))))
        / (COUNT(*) - 1) AS cov_weaning_weight
    FROM Weight JOIN Goat ON Weight.goat_id = Goat.goat_id
    WHERE EXTRACT(YEAR FROM(AGE(Weight.w_date, Goat.birthdate))) = 0 AND EXTRACT(MONTH FROM(Weight.w_date)) IN (8, 9)
    AND CAST(Goat.birthweight AS DECIMAL(4,1)) BETWEEN 1 AND 25),
CovarianceWinter AS (
    SELECT SUM((CAST(Goat.birthweight AS DECIMAL(4,1)) - (SELECT AVG(CAST(Goat.birthweight AS DECIMAL(4,1))) FROM Goat))
        * (CAST(Weight.alpha_value AS DECIMAL(4,1)) - (SELECT AVG(CAST(Weight.alpha_value AS DECIMAL(4,1))) FROM Weight JOIN Goat ON Weight.goat_id = Goat.goat_id
        WHERE EXTRACT(MONTH FROM Weight.w_date) IN (1, 11, 12))))
        / (COUNT(*) - 1) AS cov_winter_weight
    FROM Weight JOIN Goat ON Weight.goat_id = Goat.goat_id
    WHERE EXTRACT(MONTH FROM Weight.w_date) IN (1, 11, 12)
    AND CAST(Goat.birthweight AS DECIMAL(4,1)) BETWEEN 1 AND 25),
CovarianceSale AS (
    SELECT SUM((CAST(birthweight AS DECIMAL(4,1)) - (SELECT AVG(CAST(birthweight AS DECIMAL(4,1))) FROM Goat))
        * (CAST((NULLIF(last_weight, '')) AS DECIMAL(4,1)) - (SELECT AVG(CAST((NULLIF(last_weight, '')) AS DECIMAL(4,1))) FROM Goat
        WHERE goat_status = 'Sold')))
        / (COUNT(*) - 1) AS cov_sale_weight
    FROM Goat
    WHERE goat_status = 'Sold'
    AND CAST(Goat.birthweight AS DECIMAL(4,1)) BETWEEN 1 AND 25)
SELECT *
FROM Variance, CovarianceWeaning, CovarianceWinter, CovarianceSale;

CREATE VIEW BWperYear AS
SELECT EXTRACT(YEAR FROM birthdate) AS year, CAST(AVG(CAST(birthweight AS DECIMAL(4,1))) AS DECIMAL(6,3))
FROM Goat
WHERE CAST(birthweight AS DECIMAL(4,1)) > 0
GROUP BY year
ORDER BY year;