/****** Object:  StoredProcedure [dbo].[wUAOPListareFacturi]    Script Date: 01/05/2011 23:20:13 ******/
--***
/* descriere... */
create procedure  [dbo].[wUAOPListareFacturi] (@sesiune varchar(50), @parXML xml) 
as     
begin
declare @formular varchar(13),@factura varchar(13),@utilizator varchar(8),@abonat_fact varchar(13),@contract_fact varchar(13),@mesaj varchar(200),
		@inXML varchar(1),@factura_sus int,@factura_jos int,@data_fact datetime,@factura_sus_f varchar(13)
begin try
exec wIaUtilizator @sesiune, @utilizator output

select	@formular = isnull(@parXML.value('(/parametri/@formular)[1]','varchar(13)'),''),	
		@factura_sus = isnull(@parXML.value('(/parametri/@factura_sus)[1]','int'),0),	
		@factura_jos = isnull(@parXML.value('(/parametri/@factura_jos)[1]','int'),0),
		@inXML = @parXML.value('(/parametri/@inXML)[1]','varchar(1)')
        
		--@utilizator=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
   select @factura=factura,@abonat_fact=abonat,@contract_fact=contract ,@data_fact=data from FactAbon where id_factura=@factura_jos
   select @factura_sus_f=factura from FactAbon where id_factura=@factura_sus
   
   --select @utilizator,'1','FA',@factura,'',@data_fact,@abonat_fact,@factura_sus_f,'', getdate(),'','','','',0,0,0,0,0,'',0
  
  --formular
    delete from avnefac where terminal=@utilizator
	insert into avnefac(Terminal,Subunitate,Tip,Numar,Cod_gestiune,Data,Cod_tert,Factura,Contractul, 
	Data_facturii,Loc_munca,Comanda,Gestiune_primitoare,Valuta,Curs,Valoare,Valoare_valuta,Tva_11,Tva_22, 
	Cont_beneficiar,Discount) 
	values (@utilizator,'1','FA',@factura_jos,'',@data_fact,@abonat_fact,@factura_sus,'', 
	getdate(),'',@factura,'','',0,0,0,0,0,@factura_sus_f,0) 
    
    --declare @DelayLength char(8)= '00:00:01'
   -- WAITFOR delay @DelayLength
    declare @p2 xml,@paramXmlString varchar(max)
    set @paramXmlString= (select 'FA' as tip, @formular as nrform,0 as scriuavnefac,1 as debug,@abonat_fact as tert, rtrim(@factura) as numar, rtrim(@factura) as factura, @data_fact as data, @inXML as inXML for xml raw )
    exec wTipFormular @sesiune, @paramXmlString	
   
    end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end

--select * delete from IncasariFactAbon where Casier=''
--select * from incasariFactAbon
--select * from uafactabon
--select * from avnefac
