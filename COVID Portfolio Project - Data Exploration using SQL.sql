/*
Covid 19 Data Exploration :

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Use PortfolioProject

Select *
From PortfolioProject..CovidDeaths
order by 3,4

Select *
From PortfolioProject..CovidVaccinations
order by 3,4


--> Select Data that we are going to be starting with:

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 1,2


--> Total Cases vs Total Deaths:
-- Shows likelihood of dying if you contract covid in your Country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null 
order by 1,2


--> Total Cases vs Population:
-- Shows what percentage of population infected with Covid:

Select Location, date, Population, total_cases,  (total_cases/population)*100 as Percent_Population_Infected
From PortfolioProject..CovidDeaths
order by 1,2


-- Countries with Highest Infection Rate compared to Population:

Select Location, Population, MAX(total_cases) as Highest_Infection_Count,  Max((total_cases/population))*100 as Percent_Population_Infected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by Percent_Population_Infected desc -- For order by u can use ALIAS of Columns, its just for Having that u need to use the actual aggr. func.


-- Countries with Highest Death Count per Population:

Select Location, MAX(CAST(Total_deaths AS BIGINT)) as Total_Death_Count
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by Location
order by Total_Death_Count desc

sp_help CovidDeaths
SELECT * FROM CovidDeaths

--> BREAKING THINGS DOWN BY CONTINENT:

-- Showing contintents with the highest death count per population:

Select location as Continents, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null  -- where ever continents are NULL, the Location column has continents.
Group by location
order by TotalDeathCount desc


-- GLOBAL NUMBERS:

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 



--> Total Population Vs Vaccinations:
-- Shows Percentage of Population that has recieved at least one Covid Vaccine:

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3                   -- ordering by loc & date

--NOTE: u can't perform operations like division with the column u just created with another column, thus, lets use CTE here.


--> Using CTE to perform Calculation on Partition By in previous query:

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3 (ORDER BY clause cannot be in an CTE)
)
Select *, (RollingPeopleVaccinated/Population)*100 as '% of People Vaccinated'
From PopvsVac

--NOTE: if no. of columns in CTE are not same as the no. of columns in the CTE, then it will give u an error.


--> Using Temp Table to perform Calculation on Partition By in previous query:

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




--> Creating View to store data for later visualizations:

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

--NOTE: ORDER BY clause cannot be used in VIEW.


