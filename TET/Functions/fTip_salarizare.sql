--***
/**	functie Tip salarizare	*/
Create function  fTip_salarizare()
returns @tip_salarizare table
(Tip_salarizare char(2), Denumire char(50))
as
begin
insert @tip_salarizare
select '1', 'Tesa regie' 
union all 
select '2', 'Tesa acord'
union all
select '3', 'Muncitori regie' 
union all 
select '4', 'Muncitori acord individual'
union all
select '5', 'Muncitori acord colectiv' 
union all
select '6', 'Muncitori regie categoria lucrarii' 
union all
select '7', 'Muncitori acord colectiv categoria lucrarii' 
return 
end
