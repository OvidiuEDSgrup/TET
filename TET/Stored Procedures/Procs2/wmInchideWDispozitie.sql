/***--
Modifica starea dispozitiiei pt. a bloca scanarea de pe mobil.
La prima apelare, afisez meniul si apoi la confirmare schimb starea.
--***/
CREATE PROCEDURE wmInchideWDispozitie @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wmInchideWDispozitieSP')
begin 
	declare @returnValue int
	exec @returnValue = wmInchideWDispozitieSP @sesiune, @parXML output
	return @returnValue
end

declare @userASiS varchar(50), @mesaj varchar(1000), @idDisp int, @confirmInchiderea char(1), @totalScriptic decimal(12,3), @totalScanat decimal(12,3),
		@xml1 xml, @xml2 xml, @xml3 xml
		
begin try
	/*Validare utilizator */
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	
	/*Citeste variabile din parametrii */
	select	@idDisp	= ISNULL(@parXML.value('(/row/@iddisp)[1]', 'int') , 0),
			@confirmInchiderea	= @parXML.value('(/row/@confirmInchiderea)[1]', 'varchar(1)')
			
	if @idDisp=0
		raiserror('Dispozitia nu poate fi identificata.', 11, 1)
	
	if @confirmInchiderea is null
	begin
		set @totalScriptic=isnull((select sum(cantitate) from PozDispOp where idDisp=@idDisp),0)
		set @totalScanat = isnull((select sum(ps.cantitate) from PozDispOp po, PozDispScan ps where idDisp=@idDisp and po.idPoz=ps.idPoz),0)
		
		set @xml1=(select convert(varchar(30), @totalScanat) + ' / ' + convert(varchar(30), @totalScriptic) denumire, 
					'produse scanate' as info, 'back(0)' actiune
						for xml raw)
		
		set @xml2=
			(select * from
				(select null as cod, 'Confirmati inchiderea dispozitiei?' denumire, 'back(0)' actiune
				union all
					select '1' as cod, 'Da' denumire, null actiune
				union all
					select '0' as cod, 'Nu' denumire, null actiune) x
			for xml raw)
		
		select @xml1, @xml2
		 for xml path('')
	end
	else
	begin
		if @confirmInchiderea='0'
			select 'back(1)' as actiune for xml raw, root('Mesaje');
		
		if @confirmInchiderea='1' 
		begin
			/*validare introducere date necesare pe dispozitie*/
			if not exists (select 1 from AntDisp where idDisp=@idDisp and detalii.value('(/row/@gestiune)[1]','varchar(13)') is not null)
				raiserror('Inainte de inchiderea dispozitiei de receptie trebuie sa completati gestiunea!',11,1)
			if not exists (select 1 from AntDisp where idDisp=@idDisp and detalii.value('(/row/@factura)[1]','varchar(20)') is not null)
				raiserror('Inainte de inchiderea dispozitiei de receptie trebuie sa completati numarul de factura!',11,1)
			if not exists (select 1 from AntDisp where idDisp=@idDisp and detalii.value('(/row/@data_facturii)[1]','datetime') is not null)
				raiserror('Inainte de inchiderea dispozitiei de receptie trebuie sa completati data facturii!',11,1)	
		
			update AntDisp
				set stare='Scanata'
			where idDisp=@idDisp and stare='In lucru'/* mut starea doar 'in sus'. */
			
			--pentru pozitiile adaugate de pe terminal in pozdispo, la inchidere dispozitie se face cantitate=cantitate scanata	
			--pretul se ia de pe ultima receptie facuta		
			update po set po.cantitate=p.cantitate, po.pret=isnull(poz.pret_de_stoc,0)
			from PozDispOp po
				cross apply (select ps.idPoz, sum(ps.cantitate) as cantitate from PozDispScan ps where po.idPoz=ps.idPoz group by ps.idPoz) p
				outer apply (select top 1 rtrim(cod) as cod, isnull(CONVERT(decimal(17,2),Pret_de_stoc),0) as pret_de_stoc from pozdoc
					where pozdoc.Subunitate='1' and pozdoc.tip='RM' and cod=po.cod 
					order by data desc,Numar desc) poz
			where po.idDisp=@idDisp
				and po.cantitate=0	
						
			select 'back(2)' as actiune for xml raw, root('Mesaje');
		end		
		
	end
	
	select	'wmInchideWDispozitie' as _detalii, 'C' as _tipdetalii, 'refresh' as actiune, '@confirmInchiderea' _numeatr
	for xml raw, root('Mesaje');
	
end try
begin catch
	set @mesaj = ERROR_MESSAGE()+' (wmInchideWDispozitie)'
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)

/*
select * from AntDisp

select * from PozDispOp
select * from PozDispScan 

-- truncate table pozdispscan
select * from codbare
where cod_produs='PERM'



/*tipuri comenzi	bk - livrare
					bf - beneficiari 
					fc - aprovizionare
					fa - furnizori*/

INSERT INTO PozDispScan(idPoz, tipPozitie, barcode, cantitate, locatie, utilizator)
select 7, 'cantSp', null, 2, null, 'mitz'

*/
