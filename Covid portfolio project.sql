-- COVID-19 DATA EXPLORATION FROM 01/01/2020 TO 31/01/2022
-- Skills used: Joins, CTE, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types


-- Showing the full  Covid vaccination table 
select * 
from [First Portfolio]..Covidvaccinations
order by 3,4 ;

-- Showing the full covid deaths table where data on continent is not null
select * 
from [First Portfolio]..CovidDeaths
where continent is not null
order by 3,4 ;

--These are the data I'm going to be working on
--Select data to work on

select location, date, total_cases, new_cases, total_deaths, population
from [First Portfolio]..CovidDeaths
where continent is not null
order by 1, 2;

-- Taking a look at the total cases VS total death in each country
-- This shows the likelihood of a patient dying of covid-19 in poland. The current estimated percentage is 2.15% (rounded up t0 2 decimal )
select location, date, total_cases, total_deaths, round((total_deaths/total_cases) * 100, 2) as death_percentage
from [First Portfolio]..CovidDeaths
where location LIKE '%Poland%' 
order by 1, 2;

-- Taking a look at totals cases VS population
-- This shows what percentage of the population contracted covid
-- This shows that almost 13% of the population has contracted covid-19 (tested positive) at one point or the other
select location, date, population, total_cases, (total_cases/population) * 100 as PercentPopulationInfected 
from [First Portfolio]..CovidDeaths
where location LIKE '%Poland%'
order by 1, 2;

-- To get the countries with the highest infection rate compared to population
select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population)) * 100 as  PercentPopulationInfected
from [First Portfolio]..CovidDeaths
--where location LIKE '%Poland%'
where continent is not null
group by location, population
order by percentPopulationInfected DESC ;

-- Showing countries with the highest death count per population
select location, population, max(cast(total_deaths as int)) as HighestDeathCount
from [First Portfolio]..CovidDeaths
--where location LIKE '%Poland%'
where continent is not null
group by location, population
order by HighestDeathCount DESC ;

-- Now let's work on this data per continents
-- Showing the continent with the highest death count per population

select continent, max(cast(total_deaths as int)) as HighestDeathCount
from [First Portfolio]..CovidDeaths
--where location LIKE '%Poland%'
where continent is not null
group by continent
order by HighestDeathCount DESC ;

-- GLOBAL NUMBERS

-- This shows the global DeathPercentage per day
select date, sum(new_cases) as TotalNewCases, sum(cast(new_deaths as int)) as TotalNewDeaths, ( sum(cast(new_deaths as int))/sum(new_cases)) * 100 as DeathPercentage
from [First Portfolio]..CovidDeaths
--where location LIKE '%Poland%' 
where continent is not null
group by date
order by 1, 2;


-- This show the total global number 
select sum(new_cases) as TotalNewCases, sum(cast(new_deaths as int)) as TotalNewDeaths, ( sum(cast(new_deaths as int))/sum(new_cases)) * 100 as DeathPercentage
from [First Portfolio]..CovidDeaths
--where location LIKE '%Poland%' 
where continent is not null
--group by date
order by 1, 2;

-- Joining the Covid Death data and the Covid Vaccination data

select * from [First Portfolio]..CovidDeaths dea 
join [First Portfolio]..Covidvaccinations vac
on dea.location = vac.location 
and dea.date = vac.date;

-- Looking at total population VS total vaccination
select sum(dea.population) as TotalPopulation, sum(cast(vac.total_vaccinations as bigint)) as SumOfPeopleVaccinated from [First Portfolio]..CovidDeaths dea 
join [First Portfolio]..Covidvaccinations vac
on dea.location = vac.location 
and dea.date = vac.date

-- Shows Percentage of Population that has recieved at least one Covid Vaccine
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location
order by dea.location, dea.date) as AggregatePeopleVaccinated from [First Portfolio]..CovidDeaths dea 
join [First Portfolio]..Covidvaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (continent, location, date, population, new_vaccinations, AggregatePeopleVaccinated)
as (
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location
order by dea.location, dea.date) as AggregatePeopleVaccinated from [First Portfolio]..CovidDeaths dea 
join [First Portfolio]..Covidvaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select * , (AggregatePeopleVaccinated/population)* 100 as PercentagePopulationVaccinated from PopvsVac;

-- Using TEMP TABLE to perform Calculation on Partition By in previous query


DROP table if exists #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
(
continent nvarchar(255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccinations numeric,
AggregatePeopleVaccinated numeric
)
INSERT INTO #PercentagePopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location
order by dea.location, dea.date) as AggregatePeopleVaccinated from [First Portfolio]..CovidDeaths dea 
join [First Portfolio]..Covidvaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
--where dea.continent is not null
--order by 2,3
select * , (AggregatePeopleVaccinated/population)* 100 as PercentPopulationVaccinated from #PercentagePopulationVaccinated;


-- Creating view to store data for later visualizations
create view
PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,sum(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location
order by dea.location, dea.date) as AggregatePeopleVaccinated from [First Portfolio]..CovidDeaths dea 
join [First Portfolio]..Covidvaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null
--order by 2,3;

select * from PercentPopulationVaccinated