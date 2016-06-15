/***--
Procedura stocata citeste antetul Pozitiilor si le afiseaza culoarea in functie de stare:
	'#00FF00'	-->	Documentul contine pozitii care nu au fost operate
	'#000000'	--> Toate pozitiile din document au fost operate dar nu s-a generat document
	'#CCCCCC'	--> Toate poziitiile au fost operate si s-a generat document
	
param:	@sesiune	Sesiune utilizatorului curent, din care se identifica utilizatorul
		@parXML		Parametru xml in care vin datele. Se citeste:
					@tip	->	Tipul machetei curente (se citeste si trimite mai departe pentru identificare in Forms)
					@iddisp	->	Identificator unic al dispozitiei pe care se lucreaza
--***/
CREATE PROCEDURE wIaDispAW @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wIaDispAWSP')
begin 
	declare @returnValue int
	exec @returnValue = wIaDispAWSP @sesiune, @parXML output
	return @returnValue
end

declare @userASiS varchar(50), @mesaj varchar(100), @tip varchar(2), @subtip varchar(2), @iddisp int, @f_datajos datetime, @f_datasus datetime
		

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	
	/*Salveaza tip pentru retrimitere in macheta urmatoare */
	select	@tip = @parXML.value('(/row/@tip)[1]', 'varchar(2)'),
			@iddisp = isnull(@parXML.value('(/row/@iddisp)[1]','int'), -1),
			@f_datajos=isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'),'01/01/1901'),
			@f_datasus=isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'),'12/31/2999')
	
	/*Aduce datele din antet */
	select	a.idDisp iddisp, 
		max(a.descriere) descriere, 
		max(a.stare) stare, 
		--@tip tip,
		--valoarea fara tva calculata tanandu-se cont si de cantitatea diferenta
		convert(decimal(17,2),sum(isnull(convert(decimal(17,5),isnull(pc.cant_ok,0)
			+ISNULL(p.detalii.value('(/row/@cantitate_diferenta)[1]', 'float'),0)),0)*p.pret)) as valoare,
		
		--valoarea tva calculata tanandu-se cont si de cantitatea diferenta
		sum(convert(decimal(17,2),(convert(decimal(17,4),isnull(p.pret,0)*isnull(convert(decimal(17,5),isnull(pc.cant_ok,0)
			+ISNULL(p.detalii.value('(/row/@cantitate_diferenta)[1]', 'float'),0)),0)*n.cota_TVA/100)))) as valoareTVA,
		
		--valoarea cu tva calculata tanandu-se cont si de cantitatea diferenta
		convert(decimal(17,2),convert(decimal(17,5),sum(convert(decimal(17,5),isnull(pc.cant_ok,0)+ISNULL(p.detalii.value('(/row/@cantitate_diferenta)[1]', 'float'),0))*p.pret))
			+sum(round(convert(decimal(17,4),isnull(p.pret,0)*isnull(convert(decimal(17,5),isnull(pc.cant_ok,0)
			+ISNULL(p.detalii.value('(/row/@cantitate_diferenta)[1]', 'float'),0)),0)*n.cota_TVA/100),2))) as valoareTotal,
		
		(case when max(a.stare)='Finalizat' then 1 else null end) _nemodificabil,
		convert(xml,max(convert(varchar(max),a.detalii))) as detalii,
		max(convert(varchar(10),isnull(a.detalii.value('(/row/@data_facturii)[1]', 'datetime'),'12/31/2999'),101)) as data_facturii,
		rtrim(MAX(lm.Denumire)) as denlm,rtrim(MAX(g.denumire_gestiune)) as dengestiune,rtrim(MAX(t.Denumire)) as dentert,
		
		--date necesare pentru tabul de receptie
		max(convert(varchar(10),isnull(a.detalii.value('(/row/@numar_receptie)[1]', 'varchar(8)'),''),101)) as numar,
		max(convert(varchar(10),isnull(a.detalii.value('(/row/@data_receptie)[1]', 'datetime'),''),101)) as data,
		'1' as subunitate,
		'RM' as tip
	from AntDisp a
		left join PozDispOp p on p.idDisp=a.idDisp
		outer apply (select ps.idPoz, 
						sum((case when ps.tipPozitie='cantOk' then ps.cantitate else 0 end)) as cant_ok,
						sum((case when ps.tipPozitie='cantSp' then ps.cantitate else 0 end)) as cant_spart 
					from PozDispScan ps, PozDispOp po 
					where po.idDisp=a.idDisp and ps.idPoz=po.idPoz and ps.idPoz=p.idPoz
					group by ps.idPoz) pc 			
		left join nomencl n on n.cod=p.cod
		left join terti t on t.Tert=a.detalii.value('(/row/@tert)[1]','varchar(13)')
		left join lm on lm.Cod=	a.detalii.value('(/row/@lm)[1]','varchar(13)')
		left join gestiuni g on g.Cod_gestiune=a.detalii.value('(/row/@gestiune)[1]','varchar(13)')

	where @iddisp > 0 and a.idDisp = @iddisp
		or @iddisp=-1 and dataUltimeiOperatii between @f_datajos and @f_datasus
	group by a.idDisp
	order by iddisp desc
	for xml raw
	
	select 1 areDetaliiXml for xml raw, root('Mesaje')
end try
begin catch
	set @mesaj = ERROR_MESSAGE()+' (wIaDispAW)'
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
/*
select * from AntDisp
select * from PozDispOp where iddisp=88
select * from PozDispscan where idpoz=160
sp_help doc
*/
