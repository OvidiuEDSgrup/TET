create procedure wOPModificareSumaTVA @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificareSumaTVASP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModificareSumaTVASP @sesiune, @parXML
	return @returnValue
end

declare @tert varchar(30), @numar varchar(30), @data datetime, @tip varchar(2), @sumaTVA float, 
	@cotatva decimal(5,2), @stare int, @cod varchar(40), @binar varbinary(128), @bugetari int,@numar_pozitie int,@pamanunt decimal(12,2),@pvaluta decimal(12,2),@pvanzare decimal(12,2)
begin try
	select @tert=@parXML.value('(/parametri/@tert)[1]','varchar(30)'),
		@numar=@parXML.value('(/parametri/@numar)[1]','varchar(30)'),
		@numar_pozitie=isnull(@parXML.value('(/parametri/row/@numarpozitie)[1]','int'),0),
		@data=@parXML.value('(/parametri/@data)[1]','datetime'),
		@tip=@parXML.value('(/parametri/@tip)[1]','varchar(2)'),
		@cotatva=@parXML.value('(/parametri/@cotatva)[1]','decimal(5,2)'),
		@sumaTVA=@parXML.value('(/parametri/@sumaTVA)[1]','float'),
		@cod=isnull(@parXML.value('(/parametri/@cod)[1]','varchar(30)'),''),
		@pamanunt=@parXML.value('(/parametri/@pamanunt)[1]','decimal(12,2)'),
		@pvaluta=@parXML.value('(/parametri/@pvaluta)[1]','decimal(12,2)'),
		@pvanzare=@parXML.value('(/parametri/@pvanzare)[1]','decimal(12,2)')
			
	exec luare_date_par 'GE','BUGETARI', @Bugetari output, 0, ''
	set @stare=(select stare from doc where tip=@tip and Cod_tert=@tert and numar=@numar and data=@data)
	---isnull(@tva_valuta,0)=0 and abs(isnull(@suma_tva,0)-isnull(@o_suma_TVA,0))>0.05   

	if @stare<>'3' and @bugetari<>1
		raiserror('wOPModificareSumaTVA:Modificare SumaTVA nepermisa deoarece documentul nu este in stare de Operabilitate!',16,1)

	if @cod='' or @numar_pozitie=0
		raiserror('wOPModificareSumaTVA:Operatie de modificare Suma TVA neperermisa pe antetul documentului, selectati o pozitie din document, pe care se va modifica Suma TVA!',16,1)
	else
	begin
		set @binar=cast('specificebugetari' as varbinary(128))--sa se poata modifica sumatva si pe documentele definitivea
		set CONTEXT_INFO @binar	
		
		/*update pozdoc set Cota_TVA=(case when @cotatva is not null then @cotatva else Cota_TVA end), 
			TVA_deductibil=@sumatva 
		where tip=@tip and tert=@tert and numar=@numar and data=@data and cod=@cod and Numar_pozitie=@numar_pozitie
		*/
		
		if @tip in ('RM','RS') and @sumatva is not null
		begin
			update pozdoc set 
					Cota_TVA=(case when @cotatva is not null then @cotatva else Cota_TVA end), 
					TVA_deductibil=@sumatva 
				where tip=@tip and tert=@tert and numar=@numar and data=@data and cod=@cod and Numar_pozitie=@numar_pozitie
		end
		set CONTEXT_INFO 0x00
		
		if @tip in ('RM','RS') and @pamanunt is not null
		begin
			update pozdoc set pret_cu_amanuntul=@pamanunt
				where tip=@tip and tert=@tert and numar=@numar and data=@data and cod=@cod and Numar_pozitie=@numar_pozitie

			select @pvanzare=round(@pamanunt*100/(100+nomencl.cota_tva),2)
				from nomencl where nomencl.cod=@cod and nomencl.cota_tva>0

			update preturi set pret_cu_amanuntul=@pamanunt,pret_vanzare=@pvanzare
				where cod_produs=@cod and um=1 and tip_pret='1'

		end

		if @tip in ('AP','AS') and @pvaluta is not null
		begin
			update pozdoc set pret_valuta=@pvaluta, Pret_vanzare=@pvaluta*curs
				where tip=@tip and tert=@tert and numar=@numar and data=@data and cod=@cod and Numar_pozitie=@numar_pozitie
		end
	end
end try
begin catch
	declare @error varchar(500)
	set @error=ERROR_MESSAGE()
	raiserror(@error,16,1)
end catch
