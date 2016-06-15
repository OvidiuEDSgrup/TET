/***--
Procedura stocata citeste antetul Dispozitiilor si le afiseaza culoarea in functie de stare:
	'#00FF00'	-->	Documentul contine pozitii care nu au fost operate
	'#000000'	--> Toate pozitiile din document au fost operate dar nu s-a generat document
	'#CCCCCC'	--> Toate poziitiile au fost operate si s-a generat document
	
param:	@sesiune	Sesiune utilizatorului curent, din care se identifica utilizatorul
		@parXML		Parametru xml in care vin datele. Se citeste:
					@searchText ->	Textul din autoComplete dupa care se face scanarea/cautarea
--***/
CREATE PROCEDURE wmIaWReceptii @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wmIaWReceptiiSP')
begin 
	declare @returnValue int
	exec @returnValue = wmIaWReceptiiSP @sesiune, @parXML output
	return @returnValue
end

declare @userASiS varchar(50), @mesaj varchar(100), @raspuns varchar(max), @dispXML xml,
		@searchText varchar(100)
		
begin try
	/*Validare utilizator */
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	
	/*Citeste variabile din parametrii */
	select	@searchText = ISNULL(REPLACE(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'),' ', '%') ,'')
	
	
	set @raspuns=
	'<Date>'+
		ISNULL
		(
			(--afisare posibilitate de adaugare dispozitie noua de receptie
			SELECT 0 as cod,'<Dispozitie noua>' AS denumire, 'Adaugare dispozitie de receptie' AS info, '0x0000ff'AS culoare , 'C' AS _tipdetalii
				,/*'wmAdaugaWDispozitie'AS _procdetalii,*/'assets/Imagini/Meniu/AdaugProdus32.png' as poza
				--,dbo.f_wmIaForm('DR') AS 'form' 
			FOR XML RAW
			),''
		)
		+CHAR(13)+
		
		ISNULL
		(
			(--afisare dispoziiti de receptie de scanat
			select	a.idDisp as cod, max(a.descriere) as denumire,
				(case	when isnull(max(ps.articole),0)=0 then '0x000000'
						when max(ps.articole) > count(distinct(p.cod)) then '0x0000FF'
						when max(ps.articole) = count(distinct(p.cod)) and max(ps.cantitate) > SUM(p.cantitate) then '0x0000FF'
						when max(ps.articole) = count(distinct(p.cod)) and max(ps.cantitate) = SUM(p.cantitate) then '0x00FF00'
						else '0x620C0C' end) as culoare,
				ltrim(isnull(str(max(ps.articole)), '0'))+ '/' + ltrim(isnull(str(count(distinct(p.cod))),'0')) + 'produse scanate.' as info
			from AntDisp a
				left join PozDispOp p on p.idDisp = a.idDisp
				outer apply ( select count(distinct idPoz) articole, SUM(cantitate) as cantitate 
							from PozDispScan ps where ps.idPoz=p.idPoz) ps
			where a.stare in ('In lucru','De scanat') and isnull(a.descriere,'%') like '%' + @searchText + '%'
			group by a.idDisp
			order by a.idDisp 
			for xml raw
			),
			
				(--nu exista nici o dispozitie de receptie de scanat
				select 'back(1)' actiune, 'Nici o dispozitie' as denumire, 
					(case when @searchText='' then '' else 'continand "'+@searchText+'" in denumire.' end) info
				for xml raw
				)
		)
			+CHAR(13)+
	'</Date>'
	
	SELECT CONVERT(XML,@raspuns)		
		
	/*if @@ROWCOUNT=0
		select 'back(1)' actiune, 'Nici o dispozitie' as denumire, (case when @searchText='' then '' else 'continand "'+@searchText+'" in denumire.' end) info
		for xml raw
	*/
	
	select 'wmIaWPozDispReceptie' as detalii, 1 as areSearch, 0 as focusSearch, '@iddisp' as numeAtr
	for xml raw, root('Mesaje');
	
end try
begin catch
	set @mesaj = '(wmIaWReceptii)'+ERROR_MESSAGE()
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
--select * from AntDisp
--select * from PozDispOp
--select * from pozdispScan where iddisp =6
--distinct(cod) 
/*tipuri comenzi(con) 	bk - livrare
						fc - aprovizionare
						bf - beneficiari
						fa - furnizori*/
