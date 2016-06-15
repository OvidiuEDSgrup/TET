CREATE PROCEDURE wOPModificTVAExigibilFactura_p @sesiune varchar(50), @parXML xml
as
begin try
	declare 
		@tert varchar(20), @factura varchar(20), @data_facturii datetime, @tip_tva varchar(1), @mesaj varchar(max),@tip char(2)

	set @tip=@parXML.value('(/*/@tip)[1]','varchar(2)')
	set @factura=@parXML.value('(/*/@factura)[1]','varchar(20)')
	set @tert=@parXML.value('(/*/@tert)[1]','varchar(20)')
	set @data_facturii=@parXML.value('(/*/@datafacturii)[1]','datetime')

	if isnull(@factura,'')=''
		raiserror('Nu s-a putut identifica factura asociata documentului!',11,1)
	if @data_facturii is null
		raiserror('Nu s-a putut identifica data facturii!',11,1)

	
	if @tip in ('RM','RS')
	begin
		select 
			@tip_tva= 
				COALESCE(
							(select top 1 t.tip_tva from TvaPeTerti t where t.tipf='F' and t.tert=@tert and t.factura=@factura),
							(select top 1 t.tip_tva from TvaPeTerti t where t.tipf='F' and t.tert=@tert and dela<=@data_facturii order by dela desc),
							'P'							
						)
	end
	else
	begin
		set
			@tip_tva= COALESCE(
							(select top 1 t.tip_tva from TvaPeTerti t where t.tipf='B' and t.tert=@tert and t.factura=@factura),
							(select top 1 t.tip_tva from TvaPeTerti t where t.tipf='B' and t.tert is null and dela<=@data_facturii order by dela desc),
							'P')
	end


	if @tip_tva='I' and @data_facturii>'12/31/2012'
		set @tip_tva='D'
	else
		set @tip_tva='N'


	select 
		@tip_tva tip_tva, @factura factura,convert(char(10),@data_facturii,101) data_facturii
	for xml raw,root('Date')
end try
begin catch
	select 
		'1' as inchideFereastra
	for xml raw, root('Mesaje')

	set @mesaj=ERROR_MESSAGE()+ ' (wOPModificTVAExigibilFactura_p)' 
	raiserror(@mesaj, 11, 1)
	

end catch
