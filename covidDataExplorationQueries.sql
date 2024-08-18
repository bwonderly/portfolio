-- select data we will use
use CovidProject01;

-- load tables from .csv files
USE CovidProject01;
DROP TABLE IF EXISTS deaths;

CREATE TABLE deaths (
	iso_code VARCHAR(10),
    continent VARCHAR(10) NULL,
    location VARCHAR(30),
    date DATE ,
    population INT,
    total_cases INTEGER NULL,
    new_cases INTEGER NULL,
    new_cases_smoothed FLOAT NULL,
    total_deaths INTEGER NULL,
    new_deaths INTEGER NULL,
    new_deaths_smoothed FLOAT NULL,
    total_cases_per_million FLOAT NULL,
    new_cases_per_million FLOAT,
    new_cases_smoothed_per_million FLOAT NULL,
    total_deaths_per_million FLOAT NULL,
    new_deaths_per_million FLOAT NULL,
    new_deaths_smoothed_per_million FLOAT NULL,
    reproduction_rate FLOAT NULL,
    icu_patients FLOAT NULL,
    icu_patients_per_million FLOAT NULL,
    hosp_patients FLOAT NULL,
    hosp_patients_per_million FLOAT NULL,
    weekly_icu_admissions FLOAT NULL,
    weekly_icu_admissions_per_million FLOAT NULL,
    weekly_hosp_admissions FLOAT NULL,
    weekly_hosp_admissions_per_million FLOAT NULL
    );
    
LOAD DATA LOCAL INFILE '/Users/williamwonderly/Documents/SQL/covid_deaths_project/fullData/sqliteExports/covdeaths.csv'
INTO TABLE deaths
FIELDS TERMINATED BY ','
IGNORE 1 LINES
    (
	iso_code,
    continent,
    location,
    date,
    population,
    total_cases,
    new_cases,
    new_cases_smoothed,
    total_deaths,
    new_deaths,
    new_deaths_smoothed,
    total_cases_per_million,
    new_cases_per_million,
    new_cases_smoothed_per_million,
    total_deaths_per_million,
    new_deaths_per_million,
    new_deaths_smoothed_per_million,
    reproduction_rate,
    icu_patients,
    icu_patients_per_million,
    hosp_patients,
    hosp_patients_per_million,
    weekly_icu_admissions,
    weekly_icu_admissions_per_million,
    weekly_hosp_admissions,
    weekly_hosp_admissions_per_million);
    
select * from deaths;

DROP TABLE IF EXISTS vaccinations;

CREATE TABLE vaccinations (
	iso_code VARCHAR(10),
    continent VARCHAR(10),
    location VARCHAR(20),
    date DATE,
    total_tests INT,
    new_tests INT,
    total_tests_per_thousand FLOAT,
    new_tests_per_thousand FLOAT,
    new_tests_smoothed FLOAT, 
    new_tests_smoothed_per_thousand FLOAT,
    positive_rate FLOAT,
    tests_per_case FLOAT,
    tests_units FLOAT,
    total_vaccinations INTEGER,
    people_vaccinated INTEGER,
    people_fully_vaccinated INTEGER,
    total_boosters INTEGER,
    new_vaccinations FLOAT,
    new_vaccinations_smoothed FLOAT,
    total_vaccinations_per_hundred FLOAT,
    people_vaccinated_per_hundred FLOAT,
    people_fully_vaccinated_per_hundred FLOAT,
    total_boosters_per_hundred FLOAT,
    new_vaccinations_smoothed_per_million FLOAT,
    new_people_vaccinated_smoothed FLOAT,
    new_people_vaccinated_smoothed_per_hundred FLOAT,
    stringency_index FLOAT,
    population_density FLOAT,
    median_age FLOAT,
    aged_65_older FLOAT,
    aged_70_older FLOAT,
    gdp_per_capita FLOAT,
    extreme_poverty FLOAT,
    cardiovasc_death_rate FLOAT,
    diabetes_prevalence FLOAT,
    female_smokers FLOAT,
    male_smokers FLOAT,
    handwashing_facilities FLOAT,
    hospital_beds_per_thousand FLOAT,
    life_expectancy FLOAT,
    human_development_index FLOAT,
    excess_mortality_cumulative_absolute FLOAT,
    excess_mortality_cumulative FLOAT,
    excess_mortality FLOAT,
    excess_mortality_cumulative_per_million FLOAT
);

LOAD DATA LOCAL INFILE '/Users/williamwonderly/Documents/SQL/covid_deaths_project/fullData/sqliteExports/vaccines.csv'
INTO TABLE vaccinations
FIELDS TERMINATED BY ','
IGNORE 1 LINES
(
	iso_code, 
    continent, 
    location, 
    date, 
    total_tests, 
    new_tests, 
    total_tests_per_thousand, 
    new_tests_per_thousand, 
    new_tests_smoothed, 
    new_tests_smoothed_per_thousand, 
    positive_rate, 
    tests_per_case, 
    tests_units, 
    total_vaccinations, 
    people_vaccinated, 
    people_fully_vaccinated, 
    total_boosters,
    new_vaccinations, 
    new_vaccinations_smoothed, 
    total_vaccinations_per_hundred, 
    people_vaccinated_per_hundred, 
    people_fully_vaccinated_per_hundred, 
    total_boosters_per_hundred, 
    new_vaccinations_smoothed_per_million, 
    new_people_vaccinated_smoothed, 
    new_people_vaccinated_smoothed_per_hundred, 
    stringency_index,population_density, 
    median_age, 
    aged_65_older, 
    aged_70_older, 
    gdp_per_capita, 
    extreme_poverty, 
    cardiovasc_death_rate, 
    diabetes_prevalence, 
    female_smokers, 
    male_smokers, 
    handwashing_facilities, 
    hospital_beds_per_thousand, 
    life_expectancy, 
    human_development_index, 
    excess_mortality_cumulative_absolute, 
    excess_mortality_cumulative, 
    excess_mortality, 
    excess_mortality_cumulative_per_million
    );

select * from vaccinations;

-- initial data inquiry
SELECT 
    location,
    continent,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM
    deaths
WHERE continent != ''
ORDER BY 1 , 2;

-- look at total cases vs total deaths
-- shows likelihood of dying if contracted
-- how do various parameters affect this?
SELECT 
    location,
    date,
    population,
    total_cases,
	total_deaths,
    (total_deaths/total_cases) * 100 as deathPercent
FROM
    deaths
WHERE location like '%states'
ORDER BY 1 , 2;

-- looking at total cases vs population
-- estimates percentage of population that got covid
SELECT 
    location,
    date,
    population,
    total_cases,
	total_deaths,
    (total_cases/population) * 100 as casesPerPop
FROM
    deaths
WHERE location like '%states'
ORDER BY 1 , 2;

-- countries with highest infection rate as a function of population 
SELECT 
    location,
    population,
    (MAX(total_cases)/population) * 100 as casesPerPop
FROM
    deaths
GROUP BY location, population
HAVING casesPerPop > 0.01
ORDER BY casesPerPop DESC;

-- showing countries with highest death count normalized to population

SELECT 
    location,
    population,
    (MAX(total_deaths)/population)*100 deathPercent
FROM
    deaths
WHERE continent != ''
GROUP BY location, population
ORDER BY deathPercent DESC;

-- Deaths broken down by continent
SELECT 
    location,
    population,
    (MAX(total_deaths)/population)*100 deathPercent
FROM
    deaths
WHERE continent = ''
GROUP BY location, population
ORDER BY deathPercent DESC;

-- Different way to select for continent
SELECT
	continent,
	MAX(total_deaths) as TotalDeathCount
FROM 
	deaths
WHERE continent != ''
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS
SELECT 
    date,
    SUM(new_cases) AS totalCases,
    SUM(new_deaths) AS totalDeaths,
    SUM(new_deaths)/SUM(new_cases) * 100 AS deathPercent
FROM
    deaths
WHERE continent != ''
GROUP BY date
ORDER BY 1 , 2;

-- GLOBAL NUMBERS - no date
SELECT 
    SUM(new_cases) AS totalCases,
    SUM(new_deaths) AS totalDeaths,
    SUM(new_deaths)/SUM(new_cases) * 100 AS deathPercent
FROM
    deaths
WHERE continent != ''
ORDER BY 1 , 2;

-- Total Population vs Vaccinations, rolling sum
SELECT 
	d.continent, 
    d.location, 
    d.date, 
    d.population, 
    v.new_vaccinations, 
    SUM(v.new_vaccinations) OVER 
		(PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_vaccination_count
FROM deaths d
JOIN vaccinations v ON d.location = v.location AND d.date = v.date
WHERE d.continent != ''
ORDER BY 2,3;

-- Normalize vaccinations by population w CTE
-- later: try to grab the final vaccination % for each country
WITH popvsvac (continent, location, date, population, new_vaccinations, rolling_vaccination_count)
AS (SELECT 
		d.continent, 
		d.location, 
		d.date, 
		d.population, 
		v.new_vaccinations, 
		SUM(v.new_vaccinations) OVER 
			(PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_vaccination_count
	FROM deaths d
	JOIN vaccinations v ON d.location = v.location AND d.date = v.date
	WHERE d.continent != '')
    SELECT
		*, (rolling_vaccination_count/population)*100
	FROM
		popvsvac;

-- Normalize vaccinations by population w temporary table
-- later: try to grab the final vaccination % for each country
DROP TABLE IF EXISTS percentPopulationVaccinated;
CREATE TEMPORARY TABLE percentPopulationVaccinated
(
continent varchar(255),
location varchar(255),
date date,
population INT,
new_vaccinations numeric,
rolling_vaccination_count numeric
);
INSERT INTO percentPopulationVaccinated
SELECT 
	d.continent, 
    d.location, 
    d.date, 
    d.population, 
    v.new_vaccinations, 
    SUM(v.new_vaccinations) OVER 
		(PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_vaccination_count
FROM deaths d
JOIN vaccinations v ON d.location = v.location AND d.date = v.date
WHERE d.continent != '';

SELECT
	*, (rolling_vaccination_count/population)*100
FROM
	percentPopulationVaccinated;
    
-- creating view to store data for later visualizations

CREATE VIEW percentPopulationVaccinated AS 
SELECT 
	d.continent, 
    d.location, 
    d.date, 
    d.population, 
    v.new_vaccinations, 
    SUM(v.new_vaccinations) OVER 
		(PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_vaccination_count
FROM deaths d
JOIN vaccinations v ON d.location = v.location AND d.date = v.date
WHERE d.continent != ''
ORDER BY 2,3;

SELECT * FROM percentpopulationvaccinated;