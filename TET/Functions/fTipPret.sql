--***
/**	functie TipPret CM	*/
Create function  fTipPret()
returns @fTipPret table
(TipPret char(1), Denumire varchar(30))
as
begin
insert @fTipPret
select '1', 'Pret standard' 
union all 
select '2', 'Pret promo data'
union all
select '3', 'Pret promo ora' 
union all 
select '9', 'Pret impus'
return 
end
