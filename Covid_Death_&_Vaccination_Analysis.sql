--Display the tables to be utilized in the analysis

Select *
From PortfolioProject..CovidDeaths
order by 3,4

Select *
From PortfolioProject..CovidVaccinations
order by 3,4

--Select relevant data to start the analysis

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2

-- Analyze Total Cases against Total Deaths
-- Shows change in death percentage over time in the United States

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where location like '%states%'
order by 1,2

--Analyze Total Casese against Population
--Describes the percentage of the population that contracted Covid in the United States

Select Location, date, total_cases, Population, (total_cases/population)*100 as PercentageofPopulation
From PortfolioProject..CovidDeaths
where location like '%states%'
order by 1,2

--Determine countries with highest percentage of population that contracted Covid

Select Location, population, MAX(total_cases) as LargestInfectionCount, MAX((total_cases/population))*100 as PercentageofPopulation
From PortfolioProject..CovidDeaths
Group by Location, population
order by PercentageofPopulation desc

--Similar to the previous query, but includes the date of infection as well
Select Location, population, date, MAX(total_cases) as LargestInfectionCount, MAX((total_cases/population))*100 as PercentageofPopulation
From PortfolioProject..CovidDeaths
Group by Location, population, date
order by PercentageofPopulation desc

--Determine countries with highest number of deaths per population
--total_deaths is nvarchar in the imported data set, so it must be cast as int for accurate calculations to be performed
--Locations such as World, European Union, etc. are not countries and are omitted from this query 

Select Location, MAX(cast(total_deaths as int)) as DeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
and location not in ('World', 'European Union', 'International')
Group by Location
order by DeathCount desc

--Display continents with largest death count per population
--Location data based upon income will be excluded from this query

Select location, MAX(cast(total_deaths as int)) as DeathCount
From PortfolioProject..CovidDeaths
Where continent is null
and location not in ('Upper middle income', 'High income', 'Lower middle income', 'Low income','World', 'European Union', 'International')
Group by location
order by DeathCount desc

--Look at worldwide numbers

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

--Analyze Population against Vaccinations
--Describes the number of people in each country that have received a Covid vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as TotalPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
Order by 2,3

--Utilize CTE to perform calculations using the partition

With PopulationvsVaccines (continent, location, date, population, new_vaccinations, TotalPeopleVaccinated)
as
(Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as TotalPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (TotalPeopleVaccinated/population)*100
From PopulationvsVaccines


--A Temp Table can also be used to perform calculations on the partition
--DROP Table if exists #PercentageofVaccinatedPopulation can be inserted if changes to the table must be made

Create Table #PercentageofVaccinatedPopulation
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
TotalPeopleVaccinated numeric
)

Insert into #PercentageofVaccinatedPopulation
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as TotalPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *, (TotalPeopleVaccinated/population)*100
From #PercentageofVaccinatedPopulation


--Create view for data visualization

Create View PercentageofVaccinatedPopulation as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as TotalPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
