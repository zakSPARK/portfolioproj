-- SELECT * FROM CovidDeaths

-- SELECT * FROM CovidVaccinations

-- SELECT *
-- FROM analyticsportfolio..CovidVaccinations
-- order by 3

-- SELECT count(*)
-- FROM analyticsportfolio..CovidDeaths

-- select count (*)
-- from analyticsportfolio..CovidVaccinations

-- SELECT *
-- FROM analyticsportfolio..CovidVaccinations

-- SELECT [location], [date], total_cases, new_cases, total_deaths, population
-- FROM CovidDeaths
-- ORDER BY 1,2


--looking at total cases vs total deaths
--Shows the % likelihood of contacting covid in specified countries
SELECT [location], [date], total_cases, total_deaths, (total_deaths/total_cases) * 100 as '% Death'
FROM CovidDeaths
-- WHERE [location] = 'Afghanistan'
WHERE [location] LIKE '%Af%' OR [location] LIKE '%states%'
ORDER BY 1,2


--looking at total cases vs population
--showing 5 of population contaminated
SELECT [location], date, population,  (total_cases/population)*100 as '% of ContamindatedPPL',  total_cases
FROM CovidDeaths 
WHERE  [location] LIKE '%State%' OR [location] LIKE 'ca%'


--looking at countries with highest infection rates..
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)*100) as '%ofInfectedPPLTN'
FROM CovidDeaths
-- WHERE [location] LIKE '%states'
GROUP BY [location], population
ORDER BY 4 DESC


--showing countries with highest death count by location
SELECT [location], continent, MAX(cast(total_deaths as int)) as DeathCount
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY [location], continent
ORDER BY DeathCount DESC


--showing continents with highest death count by location
SELECT continent, count(cast(total_deaths as int)) as DeathCount
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY DeathCount DESC

SELECT location, count(cast(total_deaths as int)) as DeathCount
FROM CovidDeaths
WHERE continent is NULL
GROUP BY location
ORDER BY DeathCount DESC



--view by global numbers

SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/Sum(new_cases)* 100 as '% of new deaths'
FROM  CovidDeaths
WHERE continent is  not NULL
GROUP BY [date]
ORDER BY 1,2




--Vaccinations
SELECT [location], Sum(CAST(new_vaccinations as bigint)) as totalVacc, continent
FROM CovidVaccinations
GROUP BY [location], continent




--Joining  CovidDeaths table with CovidVaccines tables
SELECT cdeaths.continent, cdeaths.[location],   cdeaths.[date], cdeaths.population, cvacc.new_vaccinations
FROM CovidDeaths cdeaths JOIN CovidVaccinations cvacc
        ON cdeaths.date = cvacc.[date] AND cdeaths.[location] = cvacc.[location]
        WHERE cdeaths.continent is not NULL
        ORDER BY 1,2,3





--looking at Total Population vs Vaccination (will require we join two tables)

WITH VaccVsPopp (continent, LOCATION, date, Population, Vaccination, RollingTotalVaccines)
AS
        ( SELECT cdeaths.continent, cdeaths.[location],   cdeaths.[date], cdeaths.population, cvacc.new_vaccinations
                ,SUM(convert(bigint, cvacc.new_vaccinations)) 
                OVER (PARTITION BY cdeaths.LOCATION ORDER BY cdeaths.LOCATION, cdeaths.date) AS RollingTotalVaccines
                -- , (RollingTotalVaccines/cdeaths.population)*100
        FROM CovidDeaths cdeaths JOIN CovidVaccinations cvacc
        ON cdeaths.date = cvacc.[date] AND cdeaths.[location] = cvacc.[location]
                WHERE cdeaths.continent is not NULL
                -- ORDER BY 2,3
        )
SELECT *, (RollingTotalVaccines/Population)*100 as '% of VaccvsPopp'
From VaccVsPopp



--Creating a temporary Table

DROP TABLE IF EXISTS PercentagePopulatnVaccine
CREATE TABLE PercentagePopulatnVaccine
        (
                Continent NVARCHAR(255),
                LOCATION NVARCHAR(255),
                DATE DATETIME,
                Population NUMERIC,
                Vaccination NUMERIC,
                RollingTotalVaccination Numeric
        
        )
INSERT into PercentagePopulatnVaccine
SELECT cdeaths.continent, cdeaths.[location],   cdeaths.[date], cdeaths.population, cvacc.new_vaccinations
                ,SUM(convert(bigint, cvacc.new_vaccinations)) 
                OVER (PARTITION BY cdeaths.LOCATION ORDER BY cdeaths.LOCATION, cdeaths.date) AS RollingTotalVaccines
        FROM CovidDeaths cdeaths JOIN CovidVaccinations cvacc
        ON cdeaths.date = cvacc.[date] AND cdeaths.[location] = cvacc.[location]
                WHERE cdeaths.continent is not NULL
                ORDER BY 2,3

SELECT *, (RollingTotalVaccination/Population)*100 as '% of VaccvsPopp'
From PercentagePopulatnVaccine






--Crreating Views to store data to be used for Visualizations in Tableau or Power BI
DROP VIEW if EXISTS PercentageTotalVaccinatedPopulation
CREATE VIEW PercentageTotalVaccinatedPopulation AS
SELECT cdeaths.continent, cdeaths.[location],   cdeaths.[date], cdeaths.population, cvacc.new_vaccinations
                ,SUM(convert(bigint, cvacc.new_vaccinations)) 
                OVER (PARTITION BY cdeaths.LOCATION ORDER BY cdeaths.LOCATION, cdeaths.date) AS RollingTotalVaccines
        FROM CovidDeaths cdeaths JOIN CovidVaccinations cvacc
        ON cdeaths.date = cvacc.[date] AND cdeaths.[location] = cvacc.[location]
                WHERE cdeaths.continent is not NULL
                -- ORDER BY 2,3






/*
Queries used for Tableau Project
*/

--VIEWs used for Tableau visualization project

DROP VIEW IF Exists TabView01
CREATE VIEW TabView01 AS
SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as '%ofdeaths'
FROM CovidDeaths
WHERE continent is not NULL
-- group by [date]




-- Drop View if Exists TabView02
Create View TabView02 as
Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From CovidDeaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
-- order by TotalDeathCount desc



--Drop View if Exists TabView03
CREATE VIEW TabView03 AS
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
--Where location like '%states%'
Group by Location, Population
-- order by PercentPopulationInfected desc




--Drop View if Exists TabView04
CREATE VIEW TabView04 AS
Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
--Where location like '%states%'
Group by Location, Population, date
-- order by PercentPopulationInfected desc


