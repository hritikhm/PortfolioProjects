/*
Covid 19 Data Exploration 
Source of data: https://ourworldindata.org/covid-deaths
Data from: January 28,2020 to April30,2021

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL			--this where clause is used to remove asia,oceania,south america etc as location
ORDER BY 3,4


-- Select Data that we are going to be starting with
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Looking at TotalCases vs TotalDeaths
--shows likelihood of dying if you contract covid in India
SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location='India'
ORDER BY 1,2


--looking at totalcases vs population
--shows what percentage of population got covid
SELECT location,date,population,total_cases,(total_cases/population)*100 AS InfectionRate
FROM PortfolioProject..CovidDeaths
WHERE location='India' AND continent IS NOT NULL
ORDER BY 1,2

--Looking at countries with highest infection rate comapred to poulation
SELECT location,population,MAX(total_cases) AS HighestInfectionCount,MAX((total_cases/population)*100) AS PercentpopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location='India'
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY PercentpopulationInfected DESC


--Showing the countries with highest daeth count per population
--total_deaths in of nvarchar datatype we have to cast it
SELECT location,population,MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location='India'
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY TotalDeathCount DESC


--Let's break things by continent
--Showing continents with highest death count 
SELECT location,MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location='India'
WHERE continent IS NULL		--refer the data to understand this
GROUP BY location
ORDER BY TotalDeathCount DESC

--Global numbers
SELECT SUM(new_cases)AS TotalNewCases,SUM(CAST(new_deaths AS int)) AS TotalDeathCount,SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS NewDeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location='India'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2



--Covid Vaccination Table
SELECT * 
FROM PortfolioProject..CovidVaccinations



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT Dea.continent,Dea.location,Dea.date,Dea.population,Vac.new_vaccinations
,SUM(CAST(Vac.new_vaccinations AS int)) OVER (PARTITION BY Dea.location ORDER BY Dea.location,Dea.date) AS CumulativeSumOfNewVaccinations
--MAX(CumulativeSumOfNewVaccinations --we cant use the column we just created above for calculations,hence we need to make a CTE
FROM PortfolioProject..CovidDeaths AS Dea 
JOIN PortfolioProject..CovidVaccinations AS Vac
	ON Dea.location=Vac.location AND Dea.date=Vac.date
WHERE Dea.continent IS NOT NULL
ORDER BY 2,3



-- Using CTE to perform Calculation on Partition By in previous query
WITH PopVsVac(continent,location,date,population,new_vaccinations,CumulativeSumOfNewVaccinations)
AS(
SELECT Dea.continent,Dea.location,Dea.date,Dea.population,Vac.new_vaccinations
	,SUM(CAST(Vac.new_vaccinations AS int)) OVER (PARTITION BY Dea.location ORDER BY Dea.location,Dea.date) AS CumulativeSumOfNewVaccinations
FROM PortfolioProject..CovidDeaths AS Dea 
JOIN PortfolioProject..CovidVaccinations AS Vac
	ON Dea.location=Vac.location AND Dea.date=Vac.date
WHERE Dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT * , (CumulativeSumOfNewVaccinations/population)*100
FROM PopVsVac



-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar (255)
,location nvarchar (255)
,date datetime
,population numeric
,new_vaccinations numeric
,CumulativeSumOfNewVaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT Dea.continent,Dea.location,Dea.date,Dea.population,Vac.new_vaccinations
,SUM(CAST(Vac.new_vaccinations AS int)) OVER (PARTITION BY Dea.location ORDER BY Dea.location,Dea.date) AS CumulativeSumOfNewVaccinations
--MAX(CumulativeSumOfNewVaccinations --we cant use the column we just created above for calculations,hence we need to make a CTE
FROM PortfolioProject..CovidDeaths AS Dea 
JOIN PortfolioProject..CovidVaccinations AS Vac
	ON Dea.location=Vac.location AND Dea.date=Vac.date
WHERE Dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT * , (CumulativeSumOfNewVaccinations/population)*100
FROM #PercentPopulationVaccinated
ORDER BY 1,2


--Creating View to Store data for later visulaizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT Dea.continent,Dea.location,Dea.date,Dea.population,Vac.new_vaccinations
,SUM(CAST(Vac.new_vaccinations AS int)) OVER (PARTITION BY Dea.location ORDER BY Dea.location,Dea.date) AS CumulativeSumOfNewVaccinations
--MAX(CumulativeSumOfNewVaccinations --we cant use the column we just created above for calculations,hence we need to make a CTE
FROM PortfolioProject..CovidDeaths AS Dea 
JOIN PortfolioProject..CovidVaccinations AS Vac
	ON Dea.location=Vac.location AND Dea.date=Vac.date
WHERE Dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT * 
FROM PercentPopulationVaccinated
