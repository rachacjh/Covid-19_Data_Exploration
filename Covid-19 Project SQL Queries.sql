-- Identifying data to be used for exploration

select continent, location, date, population, total_cases, new_cases, total_deaths, new_deaths
from CovidProject.dbo.CovidDeaths



-- DAILY COUNTRY DEATH PERCENTAGES AND INFECTION RATES
-- Shows for each day, each Country's Infection Rate (likelihood of contracting Covid) and Death Percentage (likelihood of dying having contracted Covid)

select location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 DeathPercentage, (total_cases/population)*100 InfectionRate
from CovidProject.dbo.CovidDeaths
where continent is not null --and location like '%singapore%'
order by location, date desc



-- COUNTRY DEATH PERCENTAGES & INFECTION RATES ORDERED BY INFECTION RATE
-- Shows each Country's total Infection Rate and Death Percentage

select location, population, max(total_cases) as TotalCases, max(total_deaths) as TotalDeaths, max((total_cases/population)*100) as InfectionRate, max((total_deaths/total_cases)*100) as DeathPercentage
from CovidProject.dbo.CovidDeaths
where continent is not null --and location like '%singapore%'
group by location, population
order by InfectionRate desc



-- TOTAL DEATH COUNT BY CONTINENT
-- Shows each Continent's total Death Count from Covid

select location as Continent, max(cast(total_deaths as int)) as TotalDeathCount
from CovidProject.dbo.CovidDeaths
where continent is null and location not in ('World','European Union','International')
group by location
order by TotalDeathCount desc



-- DAILY TOTAL GLOBAL CASES, DEATHS & DEATH PERCENTAGE
-- Shows for each day and for all Countries as a whole, the total Cases, Deaths and Death Percentage

select date, sum(cast(new_cases as int)) as Cases, sum(cast(new_deaths as int)) as Deaths, sum(cast(new_deaths as int))/sum(cast(new_cases as int))*100 as DeathPercentage
from CovidProject.dbo.CovidDeaths
where continent is not null
group by date
order by date desc



-- ROLLING VACCINATION RATES BY COUNTRY (USING CTE)
-- Using a CTE, shows for each day, each Country's new Vaccinations and rolling percentage of Population that are Vaccinated

with VacRate (Continent, Location, Date, Population, NewVaccinations, TotalVaccinations) as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as TotalVaccinations
from CovidProject.dbo.CovidDeaths dea
join CovidProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select *, (TotalVaccinations/Population)*100 as VaccinationRate
from VacRate
--where location like '%singapore%'
order by location, date desc



-- ROLLING VACCINATION RATES BY COUNTRY (USING TEMP TABLE)
-- Using a temp table, shows for each day, each Country's new Vaccinations and rolling percentage of Population that are Vaccinated

drop table if exists #VaccinationRate
create table #VaccinationRate
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVaccinations numeric,
TotalVaccinations bigint
)

insert into #VaccinationRate
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as TotalVaccinations
from CovidProject.dbo.CovidDeaths dea
join CovidProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select *, (TotalVaccinations/Population)*100 as VaccinationRate
from #VaccinationRate
--where location like '%singapore%'
order by location, date desc



-- CREATE VIEW FOR LATER VISUALISATIONS

create view VaccinationRateView as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as TotalVaccinations
from CovidProject.dbo.CovidDeaths dea
join CovidProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null


