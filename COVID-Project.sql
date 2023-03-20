-- NOTE: In the data used, a continent is used as location in the 'Location' column to show the totals per continent.
-- 'Continent' column is null because the continent is set as location in the 'Location' column

select * 
from [portfolio-project]..['covid-death$'] 
where continent is not null
order by 3,4

select location,date,total_cases,new_cases,total_deaths,population
from [portfolio-project]..['covid-death$']
where continent is not null
order by 1,2

-- We will be looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in the United States

select location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
from [portfolio-project]..['covid-death$']
where location like '%states%' AND continent is not null
order by 1,2

-- Looking at Total Cases vs  Population
-- Shows what percentage of population got Covid

select location,date,population,total_cases, (total_cases/population)*100 AS PercentageOfPopulationInfected
from [portfolio-project]..['covid-death$']
where continent is not null
order by 1,2

-- Looking at Countries with Highest Infection Rate compared to population

select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentageOfPopulationInfected
from [portfolio-project]..['covid-death$']
where continent is not null
group by location, population
order by PercentageOfPopulationInfected desc

-- Showing the Countries with the Highest Death Count per Population

select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from [portfolio-project]..['covid-death$']
where continent is not null
group by location
order by TotalDeathCount desc

-- Let's look at it by Continent
-- Note: Since the data included other locations that are not actual continents, we need to filter them to actual continents

select location as Continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from [portfolio-project]..['covid-death$'] 
where continent is null 
and (location like '%america%' 
OR location like '%asia%' 
OR location like '%africa%'
OR location like '%europe'
OR location like '%oceania%')
group by location
order by TotalDeathCount desc

-- Global Numbers

select SUM(new_cases) as NewCases, SUM(cast(new_deaths as int)) as NewDeaths, 
(SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
from [portfolio-project]..['covid-death$'] 
where continent is not null
--group by date
order by 1,2

-- Looking at Total Population vs Vaccinations

-- We use Common Table Expression (CTE) to use the 'RollingPeopleVaccination' column to calculate the percentage of people 
-- that have been vaccinated, we'll see how it changes day by day because the number of vaccinations
-- per day get added in the 'RollingPeopleVaccination' column
with PopVSVac (Continent, Location, Date, Population, NewVaccinations, RollingPeopleVaccinated)
AS (
select dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations, 
SUM(cast(vacc.new_vaccinations as bigint)) 
OVER (Partition by dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
from [portfolio-project]..['covid-death$'] dea
JOIN [portfolio-project]..['covid-vacc$'] vacc
ON dea.location = vacc.location and dea.date = vacc.date
where dea.continent is not null
)

select *, (RollingPeopleVaccinated/Population)*100 AS PercentageofPopulationVaccinated
from PopVSVac


-- An alternative to CTE we can use a Temp Table

DROP Table if exists #PercentPopulationVaccinated

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations, 
SUM(cast(vacc.new_vaccinations as bigint)) 
OVER (Partition by dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
from [portfolio-project]..['covid-death$'] dea
JOIN [portfolio-project]..['covid-vacc$'] vacc
ON dea.location = vacc.location and dea.date = vacc.date
where dea.continent is not null

select *, (RollingPeopleVaccinated/Population)*100 AS PercentageofPopulationVaccinated
from #PercentPopulationVaccinated

-- Another alternative a View can be useful, it can be reusable

CREATE VIEW PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations, 
SUM(cast(vacc.new_vaccinations as bigint)) 
OVER (Partition by dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
from [portfolio-project]..['covid-death$'] dea
JOIN [portfolio-project]..['covid-vacc$'] vacc
ON dea.location = vacc.location and dea.date = vacc.date
where dea.continent is not null

select *, (RollingPeopleVaccinated/Population)*100 AS PercentageofPopulationVaccinated
from PercentPopulationVaccinated