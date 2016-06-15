--***
/**	functie tip CO	*/
Create function  fTip_CO()
returns @tip_co table
(Tip_concediu char(2), Denumire char(30), Denumire_scurta char(30))
as
begin
insert @tip_co
select '1', 'Anual', 'Anual'
union all
select '2', 'Evenim. tip CO', 'Evenim.tip CO'  
union all
select 'E', 'Evenim. pl.inc.', 'Evenim.plinc.'  
union all 
select '3', 'Neefectuat an curent', 'Neef.an.crt.'
union all
select '4', 'Anual an anterior', 'Anual an ant.' 
union all
select '5', 'Chemare din CO', 'Chemare-CO'
union all
select '6', 'Neefectuat an anterior', 'Neef.an.ant.'
union all 
select '7', 'Generat Anual', 'Generat Anual'
union all
select '8', 'Generat An anterior', 'Gen. an ant'
union all
select '9', 'Net', 'Net'
union all
select 'C', 'Provizion CO', 'Provizion CO' 
union all 
select 'V', 'Provizion prima vacanta', 'Provizion prima vacanta' 
union all
select 'P', 'Provizion premiu anual', 'Provizion premiu anual' 
return 
end
