
CREATE procedure  wOPCopiereTehnNomencl @sesiune varchar(50),@parXML xml
as
begin try	
	/*
		Operatia se va folosi de pe macheta de tehnologii: se introduc date pentru noul cod de nomenclator, iar procedura va asocia si tehnologie
		acestui cod (pornind de la tehnologia sursa)
	*/
	declare
		@codIntrodus varchar(20), @denIntrodus varchar(80), @grupaIntrodus varchar(20),@codTehnSursa varchar(20),
		@docNomencl xml,@docCopiereTehn xml,@idTehnologie int, @tipTehnologie varchar(1)
		
	SELECT
		@codIntrodus= @parXML.value('(/parametri/@cod)[1]','varchar(20)'),
		@denIntrodus= @parXML.value('(/parametri/@cod)[1]','varchar(80)'),
		@grupaIntrodus= @parXML.value('(/parametri/@grupa)[1]','varchar(20)'),
		@codTehnSursa= @parXML.value('(/parametri/@cod_tehn)[1]','varchar(20)'),
		@idTehnologie= @parXML.value('(/parametri/@id)[1]','int'),
		@tipTehnologie= @parXML.value('(/parametri/@tip_tehn)[1]','varchar(1)')
	
	if isnull(@codIntrodus,'')='' or isnull(@grupaIntrodus,'')='' 
		raiserror('Cod sau grupa necompletate!',11,1)	
	
	if exists(select * from nomencl where cod=@codIntrodus)
		raiserror('Codul introdus exista in nomenclator!',11,1)
			
	if isnull(@denIntrodus,'')=''
		set @denIntrodus=@codIntrodus
		
	set @docNomencl= 
	(
		select 
			@denIntrodus as denumire, @codIntrodus as cod, @grupaIntrodus as grupa,cont as cont,um as um, Cota_TVA as cotatva ,
			pret_vanzare as pretvanznom,pret_stoc as pret_stocn		
		from nomencl where cod=@codTehnSursa
		for xml raw
	)	
	exec wScriuNomenclator @sesiune=@sesiune, @parXML =@docNomencl
	
	set @docCopiereTehn=
	(
		select 
			@codIntrodus as '@codNou',@codTehnSursa as '@codNomencl',@idTehnologie as '@id',@denIntrodus as '@descriereNou',
			@codIntrodus as '@codTehnNou', @tipTehnologie as '@tip_tehn'		
		for xml path('parametri')
	)
	
	exec wOPCopiereTehn @sesiune=@sesiune, @parXML =@docCopiereTehn

END TRY
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
