/***--
Procedura stocata citeste pozitiile din Dispozitie si le afiseaza culoarea in functie de stare: - 
		DE CORECAT CULOAREA
	'#000000'	--> Pozitia nu este in starea 'Finalizat' (nu s-a generat document pe aceasta pozitie)
	'#CCCCCC'	-->	Pozitia este in starea 'Finalizat'	(s-a generat document pe aceasta pozitie)

param:	@sesiune	Sesiune utilizatorului curent, din care se identifica utilizatorul
		@parXML		Parametru xml in care vin datele. Se citeste:
					@tip	->	Tipul machetei curente (se citeste si trimite mai departe pentru identificare in Forms)
					@iddisp	->	Identificator unic al dispozitiei pe care se lucreaza
--***/
CREATE PROCEDURE wIaPozDispAW @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wIaPozDispAWSP')
begin 
	declare @returnValue int
	exec @returnValue = wIaPozDispAWSP @sesiune, @parXML output
	return @returnValue
end

declare @userASiS varchar(50), @mesaj varchar(100),
		@iddisp int, @tip varchar(2), @subtip varchar(2)

begin try
	/*Validare utilizator */
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	
	/*Ia date din parXML. Salveaza tip. */
	select	@iddisp = @parXML.value('(/row/@iddisp)[1]', 'int'),
			@tip = @parXML.value('(/row/@tip)[1]', 'varchar(2)')

	/*Aduce datele din PozDispOp */
	select	
		p.idPoz idpoz, 
		p.idDisp iddisp, 
		p.cod cod, 
		@tip tip,
		'FC' subtip, 
		CONVERT(decimal(12, 2), p.cantitate) cantitate,
		CONVERT(decimal(12,2), p.pret) pret, 
		rtrim(n.Denumire) dencod,
		ltrim(str(isnull(ps.cant_ok,0)+ISNULL(p.detalii.value('(/row/@cantitate_diferenta)[1]', 'float'),0),12,5)) as cant_ok_de_scris,
		convert(decimal(12,2),ltrim(str(isnull(ps.cant_ok,0)+ISNULL(p.detalii.value('(/row/@cantitate_diferenta)[1]', 'float'),0),12,5))*p.pret) as valoare,
		p.detalii
	from PozDispOp p 
		inner join nomencl n on p.cod=n.cod
		left join (select ps.idPoz, 
						sum((case when ps.tipPozitie='cantOk' then ps.cantitate else 0 end)) as cant_ok,
						sum((case when ps.tipPozitie='cantSp' then ps.cantitate else 0 end)) as cant_spart 
					from PozDispScan ps, PozDispOp po 
					where idDisp=@iddisp and ps.idPoz=po.idPoz
					group by ps.idPoz) ps 
			on ps.idpoz=p.idpoz
	where	p.idDisp = @iddisp
	for xml raw
	
	select 1 areDetaliiXml for xml raw, root('Mesaje')
end try
begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wIaPozDispAW)'
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
--select * from AntDisp
--select * from PozDispOp
--select * from PozDispScan
--select p.* from pozCon p where tip = 'fc' and subunitate = '1'
--select * from pozdoc where subunitate = '1' and tip = 'rm'
/* <tip()> <contract(numarDocumentSursa)> */
