--***
/* descriere... */
create procedure [dbo].[wUAOPIncasareFacturaDirect](@sesiune varchar(50), @parXML xml) 
as     
begin
declare @utilizator varchar(8),@abonat_fact varchar(13),@docXML xml,@mesaj varchar(200),@id_factura int,@factura varchar(13),
        @filtruAbonat varchar(13),@data_jos datetime,@data_sus datetime,@userASiS varchar(20),@suma_inc float,@lm varchar(13),@inXML varchar(1),
        @tip_inc varchar(2),@doc varchar(10),@data_inc datetime,@abonat varchar(13),@casier varchar(13),@teren bit,@formular varchar(20)
begin try
exec wIaUtilizator @sesiune, @utilizator output

select	@id_factura = isnull(@parXML.value('(/parametri/@id)[1]','int'),0),	
		@teren = isnull(@parXML.value('(/parametri/@teren)[1]','bit'),0),	
		@suma_inc = isnull(@parXML.value('(/parametri/@suma_inc)[1]','float'),0),
		@abonat = isnull(@parXML.value('(/parametri/@abonat)[1]','varchar(13)'),''),	
		@factura = isnull(@parXML.value('(/parametri/@factura)[1]','varchar(13)'),''),	
		@casier = isnull(@parXML.value('(/parametri/@casier)[1]','varchar(13)'),''),
		@tip_inc = isnull(@parXML.value('(/parametri/@tip_inc)[1]','varchar(2)'),''),
		@data_inc=ISNULL(@parXML.value('(/parametri/@data_inc)[1]', 'datetime'), '01-01-1901'),
		@doc = isnull(@parXML.value('(/parametri/@doc)[1]','varchar(10)'),''),
		@inXML = @parXML.value('(/parametri/@inXML)[1]','varchar(1)')
				
		
		set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')

		if (select ISNULL(sold ,0) from FactAbon where id_factura=@id_factura )<@suma_inc
				begin
				set @mesaj='Suma introdusa este mai mare decat soldul facturii!!!'
				raiserror(@mesaj,11,1)
				end

		if (select ISNULL(data,'2099-12-31') from FactAbon where id_factura=@id_factura)>@data_inc
				begin
				set @mesaj='Data incasarii este mai mica decat data facturii!!!'
				raiserror(@mesaj,11,1)
				end
				
		set @lm=(select isnull(loc_de_munca,'') from FactAbon where id_factura=@id_factura  )
		exec UAScriuIncasare 'IF',@tip_inc,@doc output,@data_inc,@abonat,@lm,@id_factura,
								 @suma_inc,0,0,@casier,0,@utilizator,@teren,''
	
	    --formular
 		select @formular =case when (@suma_inc<=(isnull((select SUM(sold) from FactAbon where abonat=@abonat and data<=@data_inc and tip not in ('AV','AP')),0)))then rtrim(Formular_chitanta) 
   		when (@suma_inc>(isnull((select SUM(sold) from FactAbon where abonat=@abonat and data<=@data_inc and tip not in ('AV','AP')),0))) 
   	    and (isnull((select SUM(sold) from FactAbon where abonat=@abonat and data<=@data_inc and tip not in ('AV','AP')),0)>0.01 ) then rtrim(Formular_chitanta_sold_avans)
   		when (isnull((select SUM(sold) from FactAbon where abonat=@abonat and data<=@data_inc and tip not in ('AV','AP')),0)=0 ) then rtrim(Formular_chitanta_avans)
   	    else '' end 
   		from casieri where Cod_casier=@utilizator   
		/*if @formular =''
		begin
			set @mesaj='Formularul nu a fost configurat !!'
			Raiserror(@mesaj,11,1)
		end*/   		
	    
		if @formular <>''
		begin
	    declare @DelayLength char(8)= '00:00:01'
		WAITFOR delay @DelayLength
		declare @p2 xml,@paramXmlString varchar(max)
		set @paramXmlString= (select 'IA' as tip, @formular as nrform,@abonat as tert, rtrim(@doc) as numar, rtrim(@doc) as factura, @data_inc as data, @inXML as inXML for xml raw )
		exec wTipFormular @sesiune, @paramXmlString
		end
    

		
		select 'S-a incasat factura '+rtrim(@factura)+' prin chitanta cu nr: '+rtrim(@doc)+' !' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
						 
   
    end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end
