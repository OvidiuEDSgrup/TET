CREATE PROCEDURE wOPModificTVAExigibilFactura @sesiune varchar(50), @parXML xml
as
begin try
	declare 
		@subunitate varchar(20),@tip char(2),@numar varchar(20),@data datetime,@tert varchar(20), @factura varchar(20), @data_facturii datetime, @tip_tva varchar(1), @mesaj varchar(max)
	
	select 
	@subunitate=@parXML.value('(/*/@subunitate)[1]','varchar(20)'),
	@tip=@parXML.value('(/*/@tip)[1]','varchar(2)'),
	@numar=@parXML.value('(/*/@numar)[1]','varchar(20)'),
	@data=@parXML.value('(/*/@data)[1]','datetime'),
	@factura=@parXML.value('(/*/@factura)[1]','varchar(20)'),
	@tert=@parXML.value('(/*/@tert)[1]','varchar(20)'),
	@data_facturii=@parXML.value('(/*/@data_facturii)[1]','datetime'),
	@tip_tva=@parXML.value('(/*/@tip_tva)[1]','varchar(1)')

	if @factura is null
		raiserror('Nu s-a putut identifica factura asociata documentului!',11,1)
	if @data_facturii is null
		raiserror('Nu s-a putut identifica data facturii!',11,1)
	if @tert is null
		raiserror('Nu s-a putut identifica tertul!',11,1)
	if @tip_tva not in ('N','D')
		raiserror('Tipul de TVA nu este corect (Neplatitor, Platitor, Incasare)!',11,1)
	if @data_facturii<'01/01/2013'
	begin
		select 'Data facturii anterioara 01.01.2013 - nu s-a facut modificarea!' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')	 
		return
	end
		
	declare @tipf varchar(1)
	set @tipf=(case when @tip in ('RM','RS') then 'F' else 'B' end)

	delete top(1) from TvaPeTerti where tipf=@tipf and tert=@tert and factura=@factura

	insert into TvaPeTerti(tipf,tert, dela,factura,tip_tva)
	select @tipf,@tert, @data_facturii, @factura, (case when @tip_tva='D' then 'I' else 'P' end)

	declare @CtTVA varchar(20),@Ct4428AV varchar(20),@Ct4426 varchar(20),@Ct4427 varchar(20),@Ct4428LaInc varchar(20),@Ct4428LaPlati varchar(20),@TipPlataTVA char(1)
	exec luare_date_par 'GE','CDTVA',0,0,@Ct4426 output
	exec luare_date_par 'GE','CCTVA',0,0,@Ct4427 output
	exec luare_date_par 'GE','CNEEXREC',0,0,@Ct4428AV output
	exec luare_date_par 'GE','CNTLIFURN',0,0,@Ct4428LaInc output
	exec luare_date_par 'GE','CNTLIBEN',0,0,@Ct4428LaPlati output

	if @tip in ('RM','RS') 
	begin

		if @tip_tva='D'
			set @CtTVA=@Ct4428LaInc 
		else 
			set @CtTva=@Ct4426

		update pozdoc set cont_venituri=@CtTVA
			where subunitate=@subunitate and tip=@tip and numar=@numar and data=@data
	end
	if @tip in ('AP','AS') 
	begin

		if @tip_tva='D'
			set @CtTVA=@Ct4428LaPlati
		else 
			set @CtTva=@Ct4427

		update pozdoc set grupa=@CtTVA
			where subunitate=@subunitate and tip=@tip and numar=@numar and data=@data
	end

end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (wOPModificTVAExigibilFactura)' 
	raiserror(@mesaj, 11, 1)

end catch
