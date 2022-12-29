/*

Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


Select *
From PortfolioProject..CovidDeaths
Where continent Is Not Null 
order by 3,4


-- Select Data that I am going to be starting with:

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent Is Not Null
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if we contract covid in our country (using Iran to can relate more) 

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 As DeathPercentage
From PortfolioProject..CovidDeaths
Where location Like '%ran'
And continent Is Not Null
Order By 1,2


-- Total Cases vs Population
-- Shows what percentage of our population infected with Covid

Select location, date, population, total_cases, (total_cases/population)*100 PopulationInfectionRate
From PortfolioProject..CovidDeaths
Where location = 'Iran' 
And continent Is Not Null
Order By 1,2


-- Countries with Highest Infection Rate compared to Population

Select location, population, Max(total_cases) TotalInfectionCount, (Max(total_cases)/population)*100  PopulationInfectionRate
From PortfolioProject..CovidDeaths
Where continent Is Not Null
Group By location, population
Order By 4 Desc
-- Iran is the 126th country in the global ranking


-- Countries with Highest Death Count per Population
-- First let's sort locations based on the Highest Death count:

Select location, MAX(Cast(total_deaths As int))TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent Is Not Null
Group By location
Order By 2 Desc

-- Now let's check the PopulationDeathRate: 
Select location, population, Max(CAST(total_deaths As int)) TotalDeathCount, 
(Max(CAST(total_deaths As int))/population)*100 PopulationDeathRate -- Or we can use CAST function to change total_deaths data type to int (Cast(total_deaths As int))
From PortfolioProject..CovidDeaths
Where continent Is Not Null
Group By location, population
Order By 4 Desc
-- Iran is the 67th country in the global ranking


-- BREAKING THINGS DOWN BY CONTINENT
-- Contintents with the Highest Death Count per Population:

Select continent, MAX(Cast(total_deaths As int))TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent Is not Null
Group By continent
Order By 2 Desc

/*
Select location, Max(CAST(total_deaths As int)) TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent Is Null
Group By location
Order By 2 Desc


Select location, MAX(Cast(total_deaths As int))TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent Is Null 
And location Not In ('High income','Upper middle income','Low income','Upper middle income','Lower middle income')
Group By location
Order By 2 Desc
*/



-- GLOBAL NUMBERS

Select date, SUM(new_cases) Total_Cases, SUM(CONVERT(int,new_deaths)) Total_Deaths, (SUM(CONVERT(int,new_deaths))/SUM(new_cases))*100 As DeathPercentage
From PortfolioProject..CovidDeaths
Where continent Is Not Null
Group By date
Order By 1


-- Overal across the world:

Select SUM(new_cases) Total_Cases, SUM(CONVERT(int,new_deaths)) Total_Deaths, (SUM(CONVERT(int,new_deaths))/SUM(new_cases))*100 As DeathPercentage
From PortfolioProject..CovidDeaths
Where continent Is Not Null


------------------------------------------------------------------------------ Total Population vs Vaccinations (Using CTE, TEMP Table and VIEW)
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

-- p.s: We want something that everytime it goes to a new location, count and start over. we don't want the SUM aggrigate to keep running and ruin our numbers --> therfore we Partition it By location and date

Select dea.continent, dea.location, dea.date, dea.population, vas.new_vaccinations,
SUM(CAST(vas.new_vaccinations As bigint)) OVER (Partition By dea.location Order By dea.location, dea.date) As RollingPeopleVaccinated 
--,(RollingPeopleVaccinated/population)*100 
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vas
	On vas.location = dea.location
	And vas.date = dea.date
Where dea.continent Is Not Null
Order By 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopVsVac As 
( Select dea.continent, dea.location, dea.date, dea.population, vas.new_vaccinations,
  SUM(CAST(vas.new_vaccinations As bigint)) OVER (Partition By dea.location Order By dea.location, dea.date) As RollingPeopleVaccinated  
  From PortfolioProject..CovidDeaths dea
  Join PortfolioProject..CovidVaccinations vas
	On vas.location = dea.location
	And vas.date = dea.date
  Where dea.continent Is Not Null
  ) 
Select *, (RollingPeopleVaccinated/population)*100 PopulationVaccinationRate
From PopVsVac
Order By location, date
-- Based on this query, up to now, in Iran 23% of Population has received at least one dose of a COVID-19 vaccine


-- Using Temp Table to perform Calculation on Partition By in previous query
-- Method #1: We can first create the Temp table and then Insert our values in it

Drop Table If Exists #PopulationVaccinationRate1
Create Table #PopulationVaccinationRate1
( continent nvarchar(225),
  location nvarchar(225),
  date date,
  population numeric,
  new_vaccinations numeric,
  RollingPeopleVaccinated numeric
  )

Insert Into #PopulationVaccinationRate1
Select dea.continent, dea.location, dea.date, dea.population, vas.new_vaccinations,
SUM(CAST(vas.new_vaccinations As bigint)) OVER (Partition By dea.location Order By dea.location, dea.date) As RollingPeopleVaccinated  
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vas
	On vas.location = dea.location
	And vas.date = dea.date
Where dea.continent Is Not Null

Select *, (RollingPeopleVaccinated/population)*100 populationvaccinationRate
From #PopulationVaccinationRate1
Order By location, date

-- Method #2: Use SELECT * INTO ...

Drop Table If Exists #PopulationVaccinationRate2
Select * Into #PopulationVaccinationRate2 
From ( Select dea.continent, dea.location, dea.date, dea.population, vas.new_vaccinations,
       SUM(CAST(vas.new_vaccinations As bigint)) OVER (Partition By dea.location Order By dea.location, dea.date) As RollingPeopleVaccinated  
       From PortfolioProject..CovidDeaths dea
       Join PortfolioProject..CovidVaccinations vas
		On vas.location = dea.location
		And vas.date = dea.date
       Where dea.continent Is Not Null
	 ) As a 
Select * From #PopulationVaccinationRate2
Order By location, date


-- Creating View to store data for later visualizations

Create View PopulationVaccinationRate As 
( Select dea.continent, dea.location, dea.date, dea.population, vas.new_vaccinations,
  SUM(CAST(vas.new_vaccinations As bigint)) OVER (Partition By dea.location Order By dea.location, dea.date) As RollingPeopleVaccinated  
  From PortfolioProject..CovidDeaths dea
  Join PortfolioProject..CovidVaccinations vas
	On vas.location = dea.location
	And vas.date = dea.date
  Where dea.continent Is Not Null
  )
Select *, (RollingPeopleVaccinated/population)*100 PopulationVaccinationRate
From PopulationVaccinationRate
Order By location, date
	   
