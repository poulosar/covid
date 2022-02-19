-- Death data query

SELECT *
FROM Covid..CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM Covid..CovidVaccinations
--ORDER BY 3,4

--Select data to use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid..CovidDeaths
ORDER BY 1,2

-- Total cases vs total deaths
-- Shows the change of dying if you catch covid
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM Covid..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2


-- Total Cases vs Populaiton
-- This shows the percent of the population that has reported as covid positive
SELECT location, date, total_cases, population, (total_cases/population)*100 as positive_percentage
FROM Covid..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2


-- Find highest death counts by country
-- Adding 'is not null' will allow us to filter out Continents from the search as well as world aggregate data
SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM Covid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count desc

-- Death counts by continent
--Is null allows us to see only the trackers for continents, this includes income level designations as well
SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM Covid..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count desc


-- Global death numbers on any given date
--Using "new" data to get aggregate data summing the total of each criteria
SELECT  date,  SUM(CAST(new_deaths as int)) as total_deaths, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as death_percentage
FROM Covid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--Global death data to date
SELECT  SUM(CAST(new_deaths as int)) as total_deaths, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as death_percentage
FROM Covid..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


--Vaccination Query

-- Population vs New Vaccinations to date
-- Join Deaths and Vaccinations on location and date as a rolling total
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.date) as rolling_country_vaccinations,

FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL -- AND dea.location LIKE'%states%'
ORDER BY 2,3


WITH PoptoVac( continent, location, date, population, new_vaccinations, rolling_country_vaccinated)
as (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.date) as rolling_country_vaccinations
FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL -- AND dea.location LIKE'%states%'
)
SELECT * , (rolling_country_vaccinated/population)*100 as rolling_percentage
FROM PoptoVac


-- Temp Table

DROP TABLE IF exists #PopulationPercentVaccinated
CREATE TABLE #PopulationPercentVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_country_vaccinated numeric
)
INSERT INTO #PopulationPercentVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.date) as rolling_country_vaccinations
FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL -- AND dea.location LIKE'%states%'
ORDER BY 2,3

SELECT * , (rolling_country_vaccinated/population)*100 as rolling_percentage
FROM #PopulationPercentVaccinated


-- View
CREATE VIEW PopulationPercentVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.date) as rolling_country_vaccinations
FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL -- AND dea.location LIKE'%states%'
--ORDER BY 2,3
