--***
create procedure wUpdateStergerePenDob @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @eroare xml ,@serie varchar(20),@prop1 varchar(20),@prop2 varchar(20),@cod varchar(20),@tip varchar(2),@update bit,@subtip varchar(2),
		@subunitate varchar(9),@numar varchar(13),@data datetime,@numar_pozitie int	,@docXMLIaPozdoc xml,@cantitate float,@gest varchar(9),@cod_intrare varchar(13),
		@userAsis varchar(13),@tert varchar(13)	,@factura varchar(20)	


begin try

	if exists (select 1 from sysobjects where [type]='P' and [name]='wUpdateStergerePenDobSP')
		exec wUpdateStergerePenDobSP @sesiune,@parXML 

	select
		 @tip=isnull(@parXML.value('(/row/@tip )[1]', 'varchar(2)'), ''),	
		 @numar=isnull(@parXML.value('(/row/@numar )[1]', 'varchar(13)'), ''),
		 @factura=isnull(@parXML.value('(/row/@factura)[1]', 'varchar(20)'), ''),
		 @tert=isnull(@parXML.value('(/row/@tert )[1]', 'varchar(13)'), ''),
		 @data=isnull(@parXML.value('(/row/@data )[1]', 'datetime'), '1901-01-01'),
		 @numar_pozitie=isnull(@parXML.value('(/row/@numarpozitie )[1]', 'int'), '')
		 	
		EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
		
		----Daca se sterge o factura generata din penalitati se apeleaza procedura care coreleaza cu penalitatile----
		if  exists (select 1 from pozdoc p 
			inner join penalizarifact pe on p.Subunitate='1' and p.tip='AS' and p.Numar=@numar and p.Tert=@tert
				and p.Tert=pe.Tert /*and p.Contract=pe.contract_coresp*/ and p.Loc_de_munca=pe.loc_de_munca
				and p.Factura=pe.factura_generata and p.Data=pe.data_factura_generata and p.Barcod in ('Dobanzi','Penalitati') 
				and left(p.Barcod,1)=rtrim(ltrim(pe.tip_penalizare))
				)--daca pozitia care se sterge o factura de penalitati sau dobanzi
			
			update pe set pe.stare='P', pe.factura_generata='', pe.data_factura_generata=null --penalitatile trec in stare "nefacturat"
			from penalizarifact pe 
				inner join pozdoc p on p.Subunitate='1' and p.tip='AS' and p.Numar=@numar and p.Tert=@tert
					and p.Tert=pe.Tert /*and p.Contract=pe.contract_coresp*/ and p.Loc_de_munca=pe.loc_de_munca
					and p.Factura=pe.factura_generata and p.Data=pe.data_factura_generata and p.Barcod in ('Dobanzi','Penalitati') 
					and left(p.Barcod,1)=rtrim(ltrim(pe.tip_penalizare))	
end try
begin catch
   ROLLBACK TRAN
	
	declare @mesaj varchar(255)
		set @mesaj=ERROR_MESSAGE()
		raiserror(@mesaj, 11, 1)
end catch
