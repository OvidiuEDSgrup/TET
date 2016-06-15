--***
create procedure wOPFacturareDeviz @sesiune varchar(50), @parXML xml                
as
declare
	@sub varchar(9), @codManopera varchar(20), @userASiS varchar(20), @gestservice varchar(9), 
	@input XML, @tipdoc varchar(2), @numar varchar(20), @data datetime, @datascad datetime, 
	@contfact varchar(13), @dencontfact varchar(80), @nrdeviz varchar(20)--, @beneficiar varchar(13)
		
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output     
exec luare_date_par @tip = 'DL', @par = 'CODMANOP', @val_l = null, @val_n = null, @val_a = @codManopera output
exec wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS output

set @gestservice = isnull((select top 1 valoare from proprietati where tip = 'UTILIZATOR' 
	and cod_proprietate = 'GSERVICE' and cod = @userASiS), '2') --tb. inlocuit '2' cu ''!!!!!!!!!!!!!!!!!!
set @nrdeviz = isnull(@parXML.value('(/parametri/@nrdeviz)[1]','varchar(8)'),'')
set @tipdoc = isnull(@parXML.value('(/parametri/@tipdoc)[1]','varchar(2)'),'AP')
set @numar = isnull(@parXML.value('(/parametri/@numar)[1]','varchar(8)'),'')
set @data = isnull(@parXML.value('(/parametri/@data)[1]','datetime'),'01/01/1901')
set @datascad = isnull(@parXML.value('(/parametri/@datascad)[1]','datetime'),'01/01/1901')
set @contfact = isnull(@parXML.value('(/parametri/@contfact)[1]','varchar(13)'),'')
set @dencontfact = isnull((select Denumire_cont from conturi where cont = @contfact), '')

begin try
	if @nrdeviz=''
	begin
			raiserror('Alegeti devizul!',11,1)
			return -1				
	end
        
	if @numar=''
	begin
			raiserror('Completati nr. doc.!',11,1)
			return -1				
	end
        
	if @data=''
	begin
			raiserror('Completati data doc.!',11,1)
			return -1				
	end
        
	if @datascad=''
	begin
			raiserror('Completati data scadentei!',11,1)
			return -1				
	end
        
	if @datascad<@data
	begin
			raiserror('Data scadentei < data doc.!',11,1)
			return -1				
	end
        
	if not exists (select 1 from conturi where Cont=@contfact and Are_analitice=0)
	begin
			raiserror('Cont inexistent sau cu analitice!',11,1)
			return -1				
	end
        
	if not exists (select 1 from devauto where Cod_deviz=@nrdeviz and Tip='B')
	begin
			   raiserror('Devizul nu este finalizat (bun de facturat)!',16,1)
			   return -1
	end	
	   
	if exists (select 1 from devauto where Cod_deviz=@nrdeviz and Stare='3')
	begin
			   raiserror('Devizul a fost facturat!',16,1)
			   return -1
	end	
	   
	if exists (select 1 from pozdoc p where subunitate=@sub and p.Numar=@numar and p.Tip='AP' and data=@data)   
	begin
			   raiserror('Doc. a fost deja generat sau exista un doc. cu nr. si data specificate!',16,1)
			   return -1
	end	
	   
	if @gestservice=''
	begin
			   raiserror('Nu aveti definita gestiunea de service (GSERVICE) ca proprietate a utilizatorului dvs.!',16,1)
			   return -1
	end
	
	/*if @beneficiar=''
	begin
		raiserror('Nu se poate genera doc. deoarece nu este completat tertul!',16,1)
		return -1
    end
	*/
	/*update pozdevauto set Cont_de_stoc=(case @tip when 'CM' then 'M' when 'AC' then 'C' 
		when 'AP' then 'A' when 'TE' then 'T' else '' end), Data_facturarii=@data, Numar_aviz=@numar
		where cod_deviz=@nrdeviz and tip='D' and Stare_pozitie='2'
		--and Numar_aviz='' 
	
	update pozdevauto set Data_facturarii=@data
		where cod_deviz=@nrdeviz and tip='D' and Stare_pozitie='2'
		--and Numar_consum<>'' 
	
	update pozdevauto set Cont_de_stoc='A'
		where cod_deviz=@nrdeviz and tip='D' and Stare_pozitie='2'
	*/
	-- se creeaza o tabela virtuala pt. pozitii
	declare @pozitii table (tip_resursa varchar(2), cod varchar(20), cantitate float, 
		Cod_intrare varchar(20), cota_tva float, discount float, pretnediscountat float, 
		pretdiscountat float, Loc_de_munca varchar(20), Locatie varchar(20), continterm varchar(20)) --a fost varchar(50) la cant. si pret!!!

	-- inserez piese
	if exists (select 1 from pozdevauto where cod_deviz=@nrdeviz and tip_resursa='P')
		insert into @pozitii(tip_resursa, cod, cantitate, Cod_intrare, cota_tva, discount, 
		pretnediscountat, pretdiscountat, Loc_de_munca, Locatie, continterm)
		select 'P', p.cod, convert(decimal(17,3),p.cantitate), p.grupa/*Cod_intrare*/, 
		isnull(pd.cota_tva,n.cota_tva), --round(p.Cantitate*pd.pret_vanzare*pd.Cota_TVA/100,2), 
		isnull(pd.discount,0), isnull(pd.pret_vanzare,n.pret_vanzare), 0, p.Loc_de_munca, '', ''
		from pozdoc p 
		left join pozdevauto pd on pd.Cod_deviz=@nrdeviz and tip_resursa='P' and pd.Cod=p.Cod 
			and pd.Numar_consum=p.Numar
		left join nomencl n on n.Cod=p.Cod
		where Subunitate=@sub and p.tip='TE' and p.Comanda=@nrdeviz
	
	-- inserez refacturari / serv.
	if exists (select 1 from pozdevauto where cod_deviz=@nrdeviz and tip_resursa in ('R','S'))
		insert into @pozitii(tip_resursa, cod, cantitate, Cod_intrare, cota_tva, discount, 
		pretnediscountat, pretdiscountat, Loc_de_munca, Locatie, continterm)
		select pd.Tip_resursa, pd.cod, convert(decimal(17,3),pd.cantitate), ''/*pd.Cod_intrare*/, 
		pd.cota_tva, --round(pd.Cantitate*pd.pret_vanzare*pd.Cota_TVA/100,2), 
		pd.discount, pd.pret_vanzare, 0, Loc_de_munca, Cod_gestiune, SUBSTRING(explicatii,11,13)
		from pozdevauto pd 			  
		where pd.Cod_deviz=@nrdeviz and tip_resursa in ('R','S')
	
	-- inserez o poz. pentru manopera
	if exists (select 1 from pozdevauto where cod_deviz=@nrdeviz and tip_resursa='M')
		insert into @pozitii(tip_resursa, cod, cantitate, Cod_intrare, cota_tva, discount, 
		pretnediscountat, pretdiscountat, Loc_de_munca, Locatie, continterm)
		select max(pd.Tip_resursa), @codManopera, 1, '', MAX(pd.cota_tva), 0, 
		convert(decimal(17,8),sum(pd.cantitate*pd.Pret_vanzare)),
		convert(decimal(17,5),sum(pd.cantitate*pd.Pret_vanzare*(1-pd.Discount/100))), 
		MAX(Loc_de_munca), '', ''
		from pozdevauto pd 
		where pd.Cod_deviz=@nrdeviz and tip_resursa='M'
	--select * from @pozitii

	set @input=(select top 1 rtrim(@numar) as '@numar', rtrim(d.beneficiar) as '@tert', 5 as '@stare', 
			rtrim(@tipdoc) as '@tip', convert(char(10),@data,101) as '@data', rtrim(@gestservice) as '@gestiune',
			convert(char(10),@data,101) as '@datafacturii', 
			convert(char(10),@datascad,101) as '@datascadentei', 
		     (select rtrim(@gestservice/*p.gestiune*/) as '@gestiune', 
		         rtrim(d.beneficiar) as '@tert', rtrim(p.Cod) as '@cod', 
				 convert(decimal(17,3), p.cantitate) as '@cantitate',				
				 rtrim(p.Loc_de_munca) as '@lm', rtrim(cod_deviz) as '@comanda', rtrim(p.Cod_intrare) as '@codintrare',
				 convert(decimal(17,2),p.cota_tva) as '@cotatva', --convert(decimal(17,2),p.) as '@sumatva', 
				 convert(decimal(17,8),p.pretnediscountat) as '@pvaluta', 
				 convert(decimal(17,5),(case when p.tip_resursa='M' 
				 then (1-pretdiscountat/pretnediscountat)*100 else p.discount end)) as '@discount', 
				 /*p.contcor as '@contcorespondent', */p.continterm as '@contintermediar', 
				 @contfact as '@contfactura', locatie as  '@locatie', --tvaneex as '@tvaneexigibil',
				 convert(char(10),@data,101) as '@dataexpirarii'
			  from @pozitii p 
		 for XML path,type)
		 from devauto d	where d.Cod_deviz=@nrdeviz 
		 for xml Path,type)
	--select @input	 
	exec wScriuPozdoc @sesiune,@input

	update pozdevauto set Cont_de_stoc=(case @tipdoc when 'CM' then 'M' when 'AC' then 'C' 
		when 'AP' then 'A' when 'TE' then 'T' else '' end), Data_facturarii=@data, Numar_aviz=@numar, 
		Stare_pozitie='3'
		where cod_deviz=@nrdeviz and tip='D' and Stare_pozitie='2'
	
	declare @datamaxfact1 datetime, @datamaxfact2 datetime
	set @datamaxfact1=isnull((select max(Data_facturarii) from pozdevauto where Cod_deviz=@nrdeviz 
		and stare_Pozitie='3'),'01/01/1901') 
	set @datamaxfact2=isnull((select max(Data_facturarii) from pozdevauto where Cod_deviz=@nrdeviz 
		and stare_Pozitie='2' and exists(select 1 from devauto where Cod_deviz=@nrdeviz and tip='N')),
		'01/01/1901') 
	set @datamaxfact1=(case when @datamaxfact1>@datamaxfact2 then @datamaxfact1 else @datamaxfact2 end)
	if @datamaxfact1<>'01/01/1901' 
		UPDATE devauto set Data_inchiderii=/*Data_lansarii */@datamaxfact1 WHERE Cod_deviz=@nrdeviz

	UPDATE devauto set Stare=isnull((select min(Stare_pozitie) from pozdevauto where Cod_deviz=@nrdeviz 
		and stare_Pozitie<>'0'),'0') 
		WHERE Cod_deviz=@nrdeviz

	UPDATE devauto set Tip='N'
		WHERE Cod_deviz=@nrdeviz
	
	declare @stareJurnal int, @docJurnal xml, @dataJurnal datetime

	set @stareJurnal = (select top 1 convert(int, Stare) from devauto where Cod_deviz = @nrdeviz)

	set @docJurnal = (select @nrdeviz as nrdeviz, @stareJurnal as stare, @data as data, 'Facturat deviz' as explicatii,
		(select rtrim(@numar) as nrdoc for xml raw, type) as detalii for xml raw, type)
	exec wScriuJurnalDeviz @sesiune = @sesiune, @parXML = @docJurnal

	select 'S-a generat doc. cu nr. ' + rtrim(@numar) + ' si cu data ' + convert(varchar(10), @data, 103) + '.' as textMesaj
	for xml raw, root('Mesaje')

end try
begin catch 
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
