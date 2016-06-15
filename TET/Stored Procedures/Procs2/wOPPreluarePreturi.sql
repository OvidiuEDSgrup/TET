create procedure wOPPreluarePreturi @sesiune varchar(50), @parXML xml                
as              

declare @datajos datetime, @datasus datetime, @catpred varchar(20), @catdest varchar(20),
		@Cod_produs varchar(40),@UM varchar(3),@Tip_pret int ,@Data_inferioara datetime ,@Ora_inferioara varchar(10),
		@Data_superioara datetime ,@Ora_superioara varchar(10),@datapret datetime,@categpret varchar(10), @pretvanz_catdest float,
		@Pret_vanzare float ,@Pret_cu_amanuntul float ,@Utilizator varchar(10),@Data_operarii datetime ,@Ora_operarii varchar(10),
		@pretaman_catdest float,@inXML xml,@tip varchar(2),@afisareRaport int,@nrprel int,@nrinserate int,@pretprel bigint,@cpGest int,@cpProp int,@i int
		,@cHostid varchar(10)
set @nrprel=0
set @nrinserate=0
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
select  @datajos= ISNULL(@parXML.value('(/parametri/@datajos)[1]', 'datetime'), ''),  
		@datasus = ISNULL(@parXML.value('(/parametri/@datasus)[1]', 'datetime'), ''),  
		@catdest = ISNULL(@parXML.value('(/parametri/@catdest)[1]', 'varchar(20)'), ''),  
		@afisareRaport= ISNULL(@parXML.value('(/parametri/@afisareRaport)[1]', 'int'), '')  
set @inXML = @parXML.value('(/parametri/@inXML)[1]','varchar(1)')
set @data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104)
set @ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
set @datapret=dateadd(d,-1,@Data_operarii)
begin try  
	if @catdest=''
		raiserror('wOPPreluarePreturi:Nu ati ales o categorie destinatara!',16,1) 
	else if @catdest='1'
		raiserror('wOPPreluarePreturi:Nu se poate prelua pret in categoria de referinta 1-Plevnei!',16,1) 
	else if @datajos>@datasus
		raiserror('wOPPreluarePreturi:Data inceput este mai mare decat data sfarsit!Preluare neefectuata!',16,1)
	  /*in cazul in care are setat gestiuni in prop sa faca verificare in caz ca nu are nimic se considera ca are drept de preluare pt orice categ*/
	set @cpGest=(case when exists (select * from  fPropUtiliz(@sesiune) fp  inner join proprietati pr on fp.cod_proprietate='GESTIUNE' 
						and pr.Cod_proprietate='CATEGPRET'and pr.cod=fp.valoare and pr.Valoare<>'') then 1 else 0 end)
	/*validare drept preluare pret pt categ pret aleasa oricare ar fi gestiunea*/
	if @cpGest=1
		begin
			if not exists (select 1 from  fPropUtiliz(@sesiune) fp  inner  join proprietati pr on fp.cod_proprietate='GESTIUNE' 
						and pr.Cod_proprietate='CATEGPRET'and pr.cod=fp.valoare and pr.Valoare<>'' and (pr.valoare=@catdest))
			raiserror('wOPPreluarePreturi:Nu aveti dreptul de preluare preturi din categoria de referinta 1 in categoria aleasa! Operatie anulata!',16,1)			
		end
	/*----------------------*/	
	set @pretprel=(select COUNT(*)
    from preturi p where p.data_inferioara  between  @datajos and @datasus and um='1' and data_superioara='2999-01-01' )
    /*iau preturile din categoria 1 cele actuale= data_superioara='2999-01-01'*/
    declare crspreturi cursor for
		select Cod_produs,Tip_pret,Data_inferioara,Data_superioara,Pret_vanzare,Pret_cu_amanuntul
		from preturi p 
		where p.data_inferioara  between @datajos and @datasus and p.um='1' and p.data_superioara='2999-01-01' 
    open crspreturi
    fetch next from crspreturi into @Cod_produs,@tip_pret,@Data_inferioara,@Data_superioara,@Pret_vanzare,@Pret_cu_amanuntul
	while @@fetch_status = 0
	begin
		set @pretvanz_catdest=(select top 1 pret_vanzare from preturi where Cod_produs=ltrim(@Cod_produs) and um=@catdest and Tip_pret=@Tip_pret order by Data_inferioara desc)
		set @pretaman_catdest=(select top 1 Pret_cu_amanuntul from preturi where Cod_produs=ltrim(@Cod_produs) and um=@catdest and Tip_pret=@Tip_pret order by Data_inferioara desc)
	/*verific daca este vreo diferenta intre preturile din cat de ref si categ aleasa*/
	if not exists (select 1 from preturi where um=@catdest and Cod_produs=@Cod_produs)
	begin
	   insert preturi (Cod_produs,UM,Tip_pret,Data_inferioara,Ora_inferioara,Data_superioara,Ora_superioara,
					   Pret_vanzare,Pret_cu_amanuntul,Utilizator,Data_operarii,Ora_operarii)
			   values (@Cod_produs, @catdest,@Tip_pret , @Data_operarii, '', '2999-01-01', '', 
					   @Pret_vanzare,@Pret_cu_amanuntul,@Utilizator,@Data_operarii,@Ora_operarii)
		set @nrinserate=@nrinserate+1
	end
	if abs(@Pret_vanzare-@pretvanz_catdest)>0.01 or abs(@Pret_cu_amanuntul-@pretaman_catdest)>0.01 
	begin
	    /*iau cea mai apropiata data inferioara a codului parcurs de data curenta in cat de pret aleasa*/
		set @Data_inferioara=(select top 1 data_inferioara from preturi where um=@catdest and Cod_produs=@Cod_produs order by Data_inferioara desc)
		update preturi set Data_superioara=@datapret
					   where um=@catdest and Cod_produs=@Cod_produs and Data_inferioara=@Data_inferioara
		insert preturi (Cod_produs,UM,Tip_pret,Data_inferioara,Ora_inferioara,Data_superioara,Ora_superioara,
					   Pret_vanzare,Pret_cu_amanuntul,Utilizator,Data_operarii,Ora_operarii)
			   values (@Cod_produs, @catdest,@Tip_pret , @Data_operarii, '', '2999-01-01', '', 
					   @Pret_vanzare,@Pret_cu_amanuntul,@Utilizator,@Data_operarii,@Ora_operarii)
		set @nrprel=@nrprel+1
	end
	 
   fetch next from crspreturi into @Cod_produs,@tip_pret,@Data_inferioara,@Data_superioara,@Pret_vanzare,@Pret_cu_amanuntul
   end
   
    begin try 
		close crspreturi 
	end try 
	begin catch end catch
	begin try 
		deallocate crspreturi 
	end try 
	begin catch end catch
	if @pretprel=0 
	    select 'wOPPreluarePreturi:Nu a fost preluat nici un pret, deoarece in intervalul '+convert(varchar(20),@datajos,103)+' - '+convert(varchar(20),@datasus,103)+'nu exista pret de preluat' as textMesaj for xml raw, root('Mesaje')
	else if @nrprel=0 and @nrinserate=0
		select 'wOPPreluarePreturi:Nu a fost preluat nici un pret, deoarece preturile din categoria '+@catdest+' coincid cu cele din categoria 1 de referinta in intervalul'+convert(varchar(20),@datajos,103)+' - '+convert(varchar(20),@datasus,103)+'' as textMesaj for xml raw, root('Mesaje')
	else if @nrprel=0 and @nrinserate>0	
	    select 'wOPPreluarePreturi:Au fost adaugate '+convert(varchar(10),@nrinserate)+' preturi din categoria 1 de referinta in categoria '+@catdest+'! in intervalul'+convert(varchar(20),@datajos,103)+' - '+convert(varchar(20),@datasus,103)+'' as textMesaj for xml raw, root('Mesaje')
	else if @nrprel>0 and @nrinserate=0	
		select 'wOPPreluarePreturi:Au fost preluate '+convert(varchar(10),@nrprel)+' preturi din categoria 1 de referinta in categoria '+@catdest+'! in intervalul'+convert(varchar(20),@datajos,103)+' - '+convert(varchar(20),@datasus,103)+'' as textMesaj for xml raw, root('Mesaje')
	else 
	   select 'wOPPreluarePreturi:Au fost preluate '+convert(varchar(10),@nrprel)+', adaugate '+convert(varchar(10),@nrinserate)+' preturi din categoria 1 de referinta in categoria '+@catdest+'! in intervalul'+convert(varchar(20),@datajos,103)+' - '+convert(varchar(20),@datasus,103)+'' as textMesaj for xml raw, root('Mesaje')
	if @afisareRaport=1 
	begin 
	    --select @nr
	    delete from anexadoc where Numele_delegatului=@Utilizator
	    if @nrprel>0 or @nrinserate>0
	    begin
	    insert into anexadoc
	    (Subunitate,Tip,Numar,Data,Numele_delegatului,Seria_buletin,Numar_buletin,
	    Eliberat,Mijloc_de_transport,Numarul_mijlocului,Data_expedierii,Ora_expedierii,Observatii,Punct_livrare,Tip_anexa)
	    values(1,'PP',@catdest,@datajos,@Utilizator,'','',
	    '','','',@datasus,@Ora_operarii,'','',1)
	    end
		declare @p2 xml,@paramXmlString varchar(max)
		/*trimit catdest in tert pentru afisare preturi vechi in formular */
		set @paramXmlString=(select 'PP' as tip, 'PP' as nrform,@datajos  as data, rtrim(@catdest) as tert, 
							RTRIM('Preturi'+@catdest+'') as numar,rtrim(@datasus) as factura ,'1' as debug,@inXML as inXML for xml raw )
		exec wTipFormular @sesiune, @paramXmlString
	  
	end 

end try  
begin catch  
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
