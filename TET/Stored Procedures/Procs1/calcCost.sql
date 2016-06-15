--***
create procedure calcCost @datajos datetime='2014-01-01', @datasus datetime='2014-01-31', @lm varchar(9)=null  
as 
-- exec calcCost @datajos='2014-08-01', @datasus='2014-08-31', @lm='1'

set nocount on
if exists(select * from sysobjects where name like 'calcul0' and type='P')
begin
	print 'Calcul 0'
    exec calcul0 @datajos,@datasus
end
print 'Inserare cheltuieli (insertchelt)'
exec insertchelt @datajos,@datasus, @lm

if exists(select * from sysobjects where name like 'calcul1' and type='P')
begin
	print 'Calcul 1'
    exec calcul1 @datajos,@datasus
end
print 'Parcurgere itinerar (itinerar)'
exec itinerar @datajos,@datasus, @lm

if exists(select * from sysobjects where name like 'calcul2' and type='P')
begin
	print 'Calcul 2'
    exec calcul2 @datajos,@datasus
end
print 'Calcul regii (regii)'
exec regii @datajos,@datasus, @lm

if exists(select * from sysobjects where name like 'calcul3' and type='P')
begin
	print 'Calcul 3'
    exec calcul3 @datajos,@datasus
end
print 'Repartizare costuri (calculcost)'
exec calculcost @datajos,@datasus, @lm

if exists(select * from sysobjects where name like 'calcul4' and type='P')
begin
	print 'Calcul 4'
    exec calcul4 @datajos,@datasus
end
print 'Inserare costuri standard (inserezcoststandard)'
exec inserezcoststandard @datajos,@datasus, @lm

if exists(select * from sysobjects where name like 'calcul5' and type='P')
begin
	print 'Calcul 5'
    exec calcul5 @datajos,@datasus
end

if exists(select * from sysobjects where name like 'calcul6' and type='P')
begin
	print 'Calcul 6'
    exec calcul6 @datajos,@datasus
end
print 'Repartizare costuri de desfacere (repAdmDesf)'
execute repAdmDesf @datajos,@datasus, @lm

if exists(select * from sysobjects where name like 'calcul7' and type='P')
begin
	print 'Calcul 7'
    exec calcul7 @datajos,@datasus
end
print 'Inlocuire preturi unitare sau gen. nota dif. (inlocPretNotaDif)'
exec inlocPretNotaDif @datajos,@datasus, @lm

if exists(select * from sysobjects where name like 'calcul8' and type='P')
begin
	print 'Calcul 8'
    exec calcul8 @datajos,@datasus
end
print 'Inserare costuri pe conturi (InsertFisaPeCont)'
exec InsertFisaPeCont @datajos,@datasus, @lm
set nocount off
