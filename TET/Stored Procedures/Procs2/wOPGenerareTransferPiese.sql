--***
create procedure wOPGenerareTransferPiese @sesiune varchar(50), @parXML xml                
as              
declare
	@sub char(9), @userASiS varchar(10), @gestservice varchar(9), @nrdeviz varchar(8),
	@numar varchar(8), @data datetime, @input XML, @docJurnal xml, @stare int
		
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output     
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @gestservice=isnull((select top 1 valoare from proprietati where tip='UTILIZATOR' 
	and cod_proprietate='GSERVICE' and cod=@userASiS), '')
set @nrdeviz = isnull(@parXML.value('(/parametri/@nrdeviz)[1]','varchar(8)'),'')
set @numar = isnull(@parXML.value('(/parametri/@numar)[1]','varchar(8)'),'')
set @data = isnull(@parXML.value('(/parametri/@data)[1]','datetime'),'01/01/1901')

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
			raiserror('Completati data!',11,1)
			return -1				
	end
        
	if exists (select 1 from pozdoc p where subunitate = @sub and p.Numar = @numar and p.Tip = 'TE' and data = @data)
	begin
			   raiserror('Exista deja un transfer cu nr. si data specificate!', 16, 1)
			   return -1
	end	
	   
	if @gestservice=''
	begin
			   raiserror('Nu aveti definita gestiunea de service (GSERVICE) ca proprietate a utilizatorului dvs.!',16,1)
			   return -1
	end

	update pozdevauto set Data_finalizarii=@data, Numar_consum=@numar
		where cod_deviz=@nrdeviz and tip='D' and tip_resursa='P' and Stare_pozitie='1'

	set @input=(select top 1 rtrim(@numar) as '@numar', 'TE' as '@tip', 
			convert(char(10),@data,101) as '@data', @gestservice as '@gestprim',
		     (select cod_gestiune as '@gestiune', rtrim(pd.Cod) as '@cod', 
				 convert(decimal(17,3),pd.cantitate) as '@cantitate',
				 convert(decimal(17,3),Round (Pret_vanzare*(1+Cota_TVA/100),3)) as '@pamanunt', 
				 Loc_de_munca as '@lm', cod_deviz as '@comanda', rtrim(pd.Cod_intrare) as '@codintrare', 
				 convert(char(10), @data, 101) as '@dataexpirarii'
			  from pozdevauto pd
			  where pd.Cod_deviz = @nrdeviz and tip = 'D' and tip_resursa = 'P' and Stare_pozitie = '1'
				and Numar_consum = @numar for xml path, type)
			 from devauto d	where d.Cod_deviz = @nrdeviz 
		 for xml Path, type)
	
	if @input.exist('/row/row') = 0
	begin
		raiserror('Nu exista piese netransferate pe acest deviz!', 16, 1)
		return
	end

	exec wScriuPozDoc @sesiune, @input
		 
	update pozdevauto set Pret_de_stoc=ISNULL((select max(Pret_de_stoc) from pozdoc where 
		Subunitate=@sub and tip='TE' and Numar=@numar and data=@data and pozdoc.Cod=pozdevauto.Cod),0)
		where cod_deviz=@nrdeviz and tip='D' and tip_resursa='P' and Stare_pozitie='1'
		and Numar_consum=@numar 
	
	update pozdevauto set Tarif_orar=Pret_de_stoc
		where cod_deviz=@nrdeviz and tip='D' and tip_resursa='P' and Stare_pozitie='1'
		and Numar_consum=@numar 
	
	update pozdevauto set Utilizator_consum=@userASiS, Stare_pozitie='2'--, Numar_consum=@numar
		where cod_deviz=@nrdeviz and tip='D' and tip_resursa='P' and Stare_pozitie='1'
		and Numar_consum=@numar 
	
	declare @datamaxfact1 datetime, @datamaxfact2 datetime
	set @datamaxfact1=isnull((select max(Data_facturarii) from pozdevauto where Cod_deviz=@nrdeviz 
		and stare_Pozitie='3'),'01/01/1901') 
	set @datamaxfact2=isnull((select max(Data_facturarii) from pozdevauto where Cod_deviz=@nrdeviz 
		and stare_Pozitie='2' and exists(select 1 from devauto where Cod_deviz=@nrdeviz and tip='N')),
		'01/01/1901') 
	set @datamaxfact1=(case when @datamaxfact1>@datamaxfact2 then @datamaxfact1 else @datamaxfact2 end)
	if @datamaxfact1<>'01/01/1901' 
		UPDATE devauto set Data_inchiderii=@datamaxfact1 WHERE Cod_deviz=@nrdeviz

	UPDATE devauto set Stare=isnull((select min(Stare_pozitie) from pozdevauto where Cod_deviz=@nrdeviz 
		and stare_Pozitie<>'0'),'0') 
		WHERE Cod_deviz=@nrdeviz

	set @stare = (select top 1 convert(int, Stare) from devauto where Cod_deviz = @nrdeviz)

	set @docJurnal = (select @nrdeviz as nrdeviz, @stare as stare, @data as data, 'Generat transfer piese' as explicatii,
		(select rtrim(@numar) as nrdoc for xml raw, type) as detalii for xml raw, type)
	exec wScriuJurnalDeviz @sesiune = @sesiune, @parXML = @docJurnal

	select 'S-a generat transferul cu nr. '+rtrim(@numar)+' si cu data '+convert(char(10),@data,103)+'.' as textMesaj for xml raw, root('Mesaje')
end try
        
begin catch 
	declare @mesajEroare varchar(500) 
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')' 
	raiserror(@mesajEroare, 16, 1) 
end catch
