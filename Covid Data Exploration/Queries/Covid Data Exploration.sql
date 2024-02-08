CREATE DATABASE covid_impact;

USE covid_impact;

SET sql_safe_updates = 0;
SET sql_mode = 'ALLOW_INVALID_DATES';

CREATE TABLE vaccinated (
  iso_code VARCHAR(10),
  continent VARCHAR(100),
  location VARCHAR(225),
  `date` DATE,
  total_cases BIGINT,
  people_vaccinated BIGINT,
  people_fully_vaccinated BIGINT,
  total_boosters BIGINT,
  population BIGINT,
  population_density FLOAT(5),
  median_age FLOAT(2)
);


CREATE TABLE casualties_n_cases (
  iso_code VARCHAR(10),
  continent VARCHAR(100),
  location VARCHAR(225),
  `date` DATE,
  total_cases BIGINT,
  new_cases BIGINT,
  total_deaths BIGINT,
  new_deaths BIGINT,
  population BIGINT
);


SELECT * FROM vaccinated;
SELECT * FROM casualties_n_cases;



-- Likelihood(Possibility) Of Being Vaccinated
SELECT iso_code, location, 100 * max(people_fully_vaccinated) / population AS fully_vaccinated_percentage
FROM vaccinated
WHERE iso_code NOT LIKE "OWID%" AND iso_code NOT IN ("GIB", "PCN")
GROUP BY iso_code
ORDER BY fully_vaccinated_percentage DESC;


-- Likelihood(Possibility) Of Being Infected
SELECT iso_code, location, 100 * max(total_cases) / population AS infected_percentage, population
FROM casualties_n_cases
WHERE iso_code NOT LIKE "OWID%"
GROUP BY iso_code
ORDER BY infected_percentage DESC;


-- Countries With Higher Death Rate Than The Global Death Rate
SELECT iso_code, location, avg(total_deaths) AS average_deaths
FROM casualties_n_cases
WHERE iso_code NOT LIKE "OWID%"
GROUP BY iso_code, location
ORDER BY average_deaths DESC;

SET @startdate := (SELECT `date` FROM casualties_n_cases ORDER BY `date` LIMIT 1);
SET @enddate := (SELECT `date` FROM casualties_n_cases ORDER BY `date` DESC LIMIT 1);

SET @globalaverage = (SELECT max(total_deaths) / datediff(@enddate, @startdate)
                        FROM casualties_n_cases
                        WHERE location = "world");
                        
SELECT @globalaverage;

SELECT "GLO" AS iso_code, "Global" AS location, round(@globalaverage, 2) AS average_deaths
UNION
SELECT iso_code, location, round(avg(total_deaths), 2) AS average_deaths
FROM casualties_n_cases
WHERE iso_code NOT LIKE "OWID%"
GROUP BY iso_code, location
HAVING average_deaths > @globalaverage
ORDER BY 3 DESC;


-- Density Of Total Cases Country-wise
SELECT iso_code, location, 100 * max(total_cases) / population AS population_percent_infected, population
FROM vaccinated
WHERE iso_code NOT LIKE "OWID%"
GROUP BY iso_code
ORDER BY population_percent_infected DESC;

DROP VIEW IF EXISTS cases_density;

CREATE VIEW cases_density
AS
SELECT iso_code, location, 100 * max(total_cases) / population AS population_percent_infected, population
FROM vaccinated
WHERE iso_code NOT LIKE "OWID%"
GROUP BY iso_code
ORDER BY population_percent_infected DESC;

SELECT * FROM cases_density;


-- Continent-wise Break Down
SELECT continent, max(total_cases) as Total_Cases, max(total_deaths) as Total_Deaths, sum(population) OVER (PARTITION BY continent) AS population
FROM casualties_n_cases
WHERE iso_code NOT LIKE "OWID%"
GROUP BY continent;