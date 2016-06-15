--***
/**	functie pt. returnare denumire tip intretinut */
Create function fTip_intretinut()
returns @tip_intretinut table
(Tip_intretinut char(2), Denumire char(30))
as
begin
	insert @tip_intretinut
	select 'A', 'Altele'
	union all
	select 'C', 'Primii 2 copii'
	union all
	select 'S', 'Sot(sotie)'
	union all 
	select 'U', 'Urmatorii copii'
	union all
	select 'E', 'Elevi'
	union all
	select 'T', 'Studenti'
	union all
	select 'R', 'Parinti pens.'
	union all 
	select 'I', 'Parinti nepens.'
	union all
	select '8', 'Generat An anterior'
	union all
	select 'B', 'Bunici'
	union all
	select 'D', 'Somer'
	union all 
	select 'M', 'Militar'
	union all
	select 'L', 'Liber profesionisti'
	union all
	select 'P', 'Pers.cf.Leg.416/20'
	union all 
	select 'G', 'Asig.cu venit agricol'
	union all
	select 'O', 'Copii peste 18 ani'

	return 
end

/*
	select * from fTip_intretinut()
*/	
