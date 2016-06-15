create procedure [dbo].[wScriuPozGP] @sesiune varchar(50), @parXML xml    
as     
declare @subtip varchar(2),@tip varchar(2),@fdataAntet datetime,@ftert varchar(20),@platitor varchar(20), @benfiban varchar(30),    
		@contpl varchar(20), @sub varchar(10),@Loc_de_munca varchar(20),@Factura varchar(20),@dataFact datetime,   
		@Data_scadentei datetime ,@Valoare float,  @Valuta varchar(10),@Curs float,@Valoare_valuta float,@sumapl float,  
		@Sold float,@Cont_de_tert varchar(10),@Achitat_valuta float,@Sold_valuta float ,@Comanda varchar(20),@Data_ultimei_achitari datetime,  
		@nrdoc varchar(20),@utilizator varchar(20),@update int,@new_observatii varchar(20), @new_sumapl varchar(20),   
		@benfbanca varchar(20),@old_observatii varchar(20),@old_sumapl varchar(20),@old_valoare varchar(20),@new_valoare varchar(20),@factprel int,@y int, @dentert varchar(20),@banca varchar(20),@dataAntet datetime,  
		@data date, @poztert varchar(20), @platiincasari bit,@numar varchar(20), @_cautare varchar(30),
		@lista_lm bit, @lm varchar(9),  @lm1 varchar(9), @observatii varchar(200),@tert varchar(20),@nr int  
begin try     
 set @factprel=0  
 set @y=0  
 exec wIaUtilizator @sesiune , @utilizator output    
 --Tin cont de filtru pe LM din proprietati pe utilizatori  
 select @lista_lm=0  
 select @lista_lm=(case when cod_proprietate='LOCMUNCA' and Valoare<>'' then 1 else @lista_lm end)   
    from proprietati   
    where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate in ('LOCMUNCA') and valoare<>''  
 --   
select	@subtip=ISNULL(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'), ''),    
		@poztert=ISNULL(@parXML.value('(/row/linie/@tert)[1]', 'varchar(20)'), ''),  
		@fdataAntet=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'),'2010-12-01'),  
		@nrdoc=isnull(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),  
		@update=isnull(@parXML.value('(/row/row/@update)[1]', 'int'), 0),  
		@old_observatii=isnull(@parXML.value('(/row/row/@o_observatii)[1]', 'varchar(20)'), ''),  
		@new_observatii=isnull(@parXML.value('(/row/row/@observatii)[1]', 'varchar(20)'), ''),  
		@old_sumapl=isnull(@parXML.value('(/row/row/@o_valfact)[1]', 'varchar(20)'), ''),
		@new_sumapl=isnull(@parXML.value('(/row/row/@valfact)[1]', 'varchar(20)'), ''),  
		@old_valoare=isnull(@parXML.value('(/row/row/@o_valoare)[1]', 'varchar(20)'), ''),  
		@new_valoare=isnull(@parXML.value('(/row/row/@valoare)[1]', 'varchar(20)'), ''),  
		@benfbanca=isnull(@parXML.value('(/row/@benfbanca)[1]', 'varchar(20)'), ''),  
		@platiincasari=isnull(@parXML.value('(/row/row/@platiincasari)[1]', 'bit'), 0),
		@_cautare=isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(30)'), '')  
       
 select	@dentert= (select denumire from terti where tert=@ftert),  
		@Factura=(case when @subtip in ('F','G')  then isnull(@parXML.value('(/row/row/@factura)[1]', 'varchar(20)'), '')end),  
		@datafact=(case when @subtip in ('F','G')  then isnull(@parXML.value('(/row/row/@datafacturii)[1]', 'varchar(20)'), '')end),
		@lm=rtrim(ltrim(isnull(@parXML.value('(/row/row/@lm)[1]', 'varchar(9)'), ''))),    
		@contpl=isnull((select cont from ccontaiban),''),   
		@platitor=isnull((select cod from ccontaiban),'')  
 exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output  
 
 --  
	if @nrdoc=''   
	begin  
		set @numar=isnull((select MAX(substring(Numar_document,4,4)) from generareplati where Numar_document like 'BSE%'),1)+1  
		set @nrdoc='BSE'+@numar  
    end   
 --  
if @subtip='ID' -- populare din tabela facturi, dar nu si cele care apar in ordine de plata valide  
	begin   
        insert into generareplati  
				(Tip,Element,Data,Tert, Factura,Numar_document,Numar_ordin,Suma_platita,  
				Detalii_plata, Cont_platitor,IBAN_beneficiar,Banca_beneficiar, Alfa1,Alfa2,Alfa3,  
				Val1,Val2,Val3, Data1,Data2,Data3,Stare,Loc_de_munca)   
		select 'P','F',@fdataAntet, t.tert, f.Factura,@nrdoc,'', f.sold, 
				'', @platitor, t.cont_in_banca, t.banca,'','','',
				0,'','',f.data, f.data_scadentei, convert(datetime, convert(char(10), getdate(),104), 104),0, f.loc_de_munca 
		from facturi f inner join  terti t on t.tert=f.tert  
							where f.tip='T' and f.sold>=0.01   
								and f.cont_de_tert not in ('408','462')  
								and not exists (select 1 from generareplati g where g.tip='P' and g.element='F' and g.tert=f.tert and g.factura=f.factura and g.data1=f.data and g.stare='1')  
								and (@lm='' or f.loc_de_munca=@lm)   and (@lista_lm=0 or f.loc_de_munca in (select cod from LMfiltrare where utilizator=@utilizator)) 
		select @y= count(*) from facturi f 
							inner join  terti t on t.tert=f.tert  
							where f.tip='T' and f.sold>=0.01   
								and f.cont_de_tert not in ('408','462')  
								and not exists (select 1 from generareplati g where g.tip='P' and g.element='F' and g.tert=f.tert and g.factura=f.factura and g.data1=f.data and g.stare='1' )  
								and (@lm='' or f.loc_de_munca=@lm)   and (@lista_lm=0 or f.loc_de_munca in (select cod from LMfiltrare where utilizator=@utilizator))  
    
		
	end
else
  ---------------acest subtip permite editarea campului suma de platit in cazul unei facturi-----------------  
if @subtip='G' and @update=1  
	begin  
		if ltrim(rtrim(isnull(@new_sumapl,''))) in ('0','0.00','0.0','')  
			set @new_sumapl=@new_valoare  
			update generareplati set val1=@new_sumapl, val3=@platiincasari where Factura=@factura and data=@fdataAntet and tert=@poztert and Numar_document=@nrdoc  
	end    
if @subtip='F' and @update=1  
	update generareplati set val3=@platiincasari where Factura=@factura and data=@fdataAntet and tert=@poztert and Numar_document=@nrdoc  

else  
	if @subtip='IF'   
	begin  
		declare @tertpoz varchar(20),@facturitza varchar(20), @suma float  
		select	@facturitza=isnull(@parXML.value('(/row/row/@factura)[1]', 'varchar(20)'), ''),  
				@tertpoz=isnull(@parXML.value('(/row/row/@tert)[1]', 'varchar(20)'), ''),  
				@suma=isnull(@parXML.value('(/row/row/@sumapl)[1]', 'varchar(20)'), '0')     
	
        insert into generareplati  
				(Tip,Element,Data,Tert,Factura,Numar_document,Numar_ordin,Suma_platita,  
				Detalii_plata, Cont_platitor,IBAN_beneficiar,Banca_beneficiar,  
				Alfa1,Alfa2,Alfa3, Val1,Val2,Val3,  Data1,Data2,
				Data3, Stare,Loc_de_munca)   
		select 'P','F',@fdataAntet, t.tert, f.Factura,@nrdoc, '',f.sold, 
				'',@platitor, t.cont_in_banca, t.banca,
				'','','',(case when @suma=0 then f.sold else @suma end),'','', f.data, f.data_scadentei, 
				convert(datetime, convert(char(10), getdate(),104), 104),0,f.loc_de_munca  
		from facturi f, terti t   
			where f.tert=@tertpoz   
			and (@facturitza='' or f.factura=@facturitza) and t.tert=f.tert   
			and f.tip='T' and f.sold>=0.01   and f.cont_de_tert not in ('408','462')  
			and not exists (select 1 from generareplati g where g.tip='P' and g.element='F' and g.tert=f.tert and g.factura=f.factura and g.Data1=f.data and g.stare='1')  
			and (@lm='' or f.loc_de_munca=@lm)   
			and (@lista_lm=0 or f.loc_de_munca in (select cod from LMfiltrare where utilizator=@utilizator))      

	select @y=count(*) from facturi f, terti t   
			where f.tert=@tertpoz   
			and (@facturitza='' or f.factura=@facturitza) and t.tert=f.tert   
			and f.tip='T'and f.sold>=0.01   and f.cont_de_tert not in ('408','462')  
			and not exists (select 1 from generareplati g where g.tip='P' and g.element='F' and g.tert=f.tert and g.factura=f.factura and g.Data1=f.data and g.stare='1')  
			and (@lm='' or f.loc_de_munca=@lm) and (@lista_lm=0 or f.loc_de_munca in (select cod from LMfiltrare where utilizator=@utilizator))      

    end  
   else  
    if @subtip='PF'  
     begin  
		  select	@tert=isnull(@parXML.value('(/row/row/@tert)[1]', 'varchar(20)'), ''),  
					@observatii=isnull(@parXML.value('(/row/row/@observatii)[1]', 'varchar(200)'), ''),  
					@sumapl=isnull(@parXML.value('(/row/row/@sumapl)[1]', 'varchar(20)'), '0')  ,
					@benfiban=ISNULL((select cont_in_banca from terti where tert=@tert),''),
					@banca=ISNULL((select banca from terti where tert=@tert),'')  
		if @lm='' and @lista_lm=1  
			set @lm=(select min(cod) from LMfiltrare where utilizator=@utilizator)  
		if @lm=''  
			set @lm='1'  
		set @nr=isnull((select MAX(rtrim(ltrim(factura))) from generareplati where Numar_document=@nrdoc and 
													data=@fdataAntet and tert=@tert and tip='P' and element='N'),0)+1  
		insert into generareplati  
				(Tip,Element,Data,Tert, Factura,Numar_document,Numar_ordin,Suma_platita,  
				Detalii_plata, Cont_platitor,IBAN_beneficiar,Banca_beneficiar,  
				Alfa1,Alfa2,Alfa3, Val1,Val2,Val3, Data1,Data2,Data3,  
				Stare,Loc_de_munca)   
        values('P','N',@fdataAntet,@tert, @nr,@nrdoc,'',0,  
				@observatii,  @platitor,@benfiban,@banca,  
				'','','', @sumapl,0,0,  @fdataAntet,@fdataAntet,convert(datetime, convert(char(10), getdate(),104), 104),  
				'0',@lm)    
     end   
 --  
if @y=0 and @subtip='ID'   
		raiserror('Nu sunt facturi cu data scadenta aleasa!',16,1) 
else if @y=0 and @subtip='IF' and @facturitza<>''   
		raiserror('Nu exista factura aleasa!',16,1)
	 else if @y=0 and @subtip='IF'
		raiserror('Nu sunt facturi pentru tertul/loc munca ales!',16,1)
		
		declare @docXMLIaPozGP xml    
		set @docXMLIaPozGP = '<row numar="' + rtrim(@nrdoc) + '" data="' + convert(varchar(20), @fdataAntet, 101)+'" _cautare="'+@_cautare+'"/>'    
		exec wIaPozGP @sesiune=@sesiune, @parXML=@docXMLIaPozGP		
end try    
--  
begin catch    
    declare @eroare varchar(500)  
	set @eroare=ERROR_MESSAGE()  
	raiserror(@eroare, 16, 1)   
end catch  
--