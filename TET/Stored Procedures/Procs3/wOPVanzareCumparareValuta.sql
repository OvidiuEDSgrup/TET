--***
create procedure wOPVanzareCumparareValuta @sesiune varchar(50), @parXML xml 
as     
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPVanzareCumparareValutaSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPVanzareCumparareValutaSP @sesiune, @parXML output
	return @returnValue
end

declare @mesaj varchar(500),@utilizator varchar(20),@sub varchar(9),@cont_dif_curs varchar(40),@cont_disp_lei varchar(40),@cont_disp_valuta varchar(40),
	@cont_trecere varchar(40),@curs_BC float,@curs_BNR float,@numar varchar(8),@data datetime,@dif_curs_lei float,@suma_lei_BC float,@suma_lei_BNR float,
	@suma_valuta float,@lm varchar(13),@valuta varchar(3),@tiptranzactie varchar(2),@cu_dif_curs_cont_valuta int
begin try		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	select 
		@numar=upper(ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(8)'), '')),
		@data=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), ''),
		@cont_dif_curs=ISNULL(@parXML.value('(/parametri/@cont_dif_curs)[1]', 'varchar(40)'), ''),
		@cont_disp_lei=ISNULL(@parXML.value('(/parametri/@cont_disp_lei)[1]', 'varchar(40)'), ''),
		@cont_disp_valuta=ISNULL(@parXML.value('(/parametri/@cont_disp_valuta)[1]', 'varchar(40)'), ''),
		@cont_trecere=ISNULL(@parXML.value('(/parametri/@cont_trecere)[1]', 'varchar(40)'), ''),
		@curs_BC=ISNULL(@parXML.value('(/parametri/@curs_BC)[1]', 'float'), 0),
		@curs_BNR=ISNULL(@parXML.value('(/parametri/@curs_BNR)[1]', 'float'), 0),
		@dif_curs_lei=ISNULL(@parXML.value('(/parametri/@dif_curs_lei)[1]', 'float'), 0),
		@suma_lei_BC=ISNULL(@parXML.value('(/parametri/@suma_lei_BC)[1]', 'float'), 0),
		@suma_lei_BNR=ISNULL(@parXML.value('(/parametri/@suma_lei_BNR)[1]', 'float'), 0),
		@suma_valuta=ISNULL(@parXML.value('(/parametri/@suma_valuta)[1]', 'float'), 0),
		@cu_dif_curs_cont_valuta=ISNULL(@parXML.value('(/parametri/@cu_dif_curs_cont_valuta)[1]', 'int'), 0),
		@lm=ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(13)'), ''),
		@valuta=ISNULL(@parXML.value('(/parametri/@valuta)[1]', 'varchar(3)'), ''),
		@tiptranzactie=ISNULL(@parXML.value('(/parametri/@tiptranzactie)[1]', 'varchar(2)'), '')
		
	if isnull(@numar,'')=''
	begin
		set @mesaj='Introduceti numarul!'
		raiserror(@mesaj,11,1)
	end	
			
	if not exists (select 1 from valuta where valuta=@valuta)
	begin
		set @mesaj='Valuta inexistenta!'
		raiserror(@mesaj,11,1)
	end	
	
	set @suma_lei_BC=convert(decimal(17,5),@suma_valuta*@curs_BC)
	set @suma_lei_BNR=convert(decimal(17,5),@suma_valuta*@curs_BNR)
	set @dif_curs_lei=convert(decimal(17,5),@suma_lei_BC-@suma_lei_BNR)
	set @dif_curs_lei=(case when @dif_curs_lei<0 then @dif_curs_lei*(-1)else @dif_curs_lei end)
	
	set @cont_dif_curs=case when @tiptranzactie <>'CV' and @curs_BNR>@curs_BC OR @tiptranzactie='CV' and @curs_BNR<@curs_BC then '665' else '765' end
	
	declare @input XMl	
	set @input=(select top 1 rtrim(@sub) as '@subunitate','RE' as '@tip',
					rtrim(@cont_disp_valuta) as '@cont', convert(char(10),@data,101) as '@data',
				
				(select  rtrim(@numar) as '@numar',
					case when isnull(@cont_trecere,'')='' then rtrim(@cont_dif_curs) else rtrim(@cont_trecere) end as '@contcorespondent', 
					(case when @tiptranzactie='CV' then 'ID' else 'PD' end) as '@subtip',
					(case when @cu_dif_curs_cont_valuta=1 then convert(decimal(17,5),@suma_lei_BC) else convert(decimal(17,5),@suma_lei_BNR) end) as '@suma',
					rtrim(@valuta) as '@valuta',convert(decimal(17,5),@suma_valuta)as '@sumavaluta',
					(case when @cu_dif_curs_cont_valuta=1 then convert(decimal(17,5),@curs_BC) else convert(decimal(17,5),@curs_BNR) end) as '@curs',
					(case when @tiptranzactie='CV' then 'Cumparare valuta' else 'Vanzare valuta' end) as '@explicatii',
					RTRIM(@lm) as '@lm'				 
					for XML path,type)
				for xml Path,type)	 
	--select @input
	exec wScriuPozplin @sesiune,@input
	
	
	declare @input1 XMl	
	set @input1=(select top 1 rtrim(@sub) as '@subunitate','RE' as '@tip',
					(case when @cu_dif_curs_cont_valuta=1 then rtrim(@cont_disp_valuta) else rtrim(@cont_disp_lei) end )as '@cont', 
					convert(char(10),@data,101) as '@data',
				
				(select  rtrim(@numar) as '@numar',
					rtrim(@cont_dif_curs) as '@contcorespondent', 
					(case when Left (@cont_dif_curs,1)='6' then 'PD' else 'ID' end) as '@subtip',
					convert (decimal(17,5),@dif_curs_lei) as '@suma',
					(case when @tiptranzactie='CV' then 'Cumparare valuta' else 'Vanzare valuta' end) as '@explicatii'	,	
					RTRIM(@lm) as '@lm'				 
					for XML path,type)
				for xml Path,type)	 
	--select @input
	exec wScriuPozplin @sesiune,@input1
	
	
	declare @input2 XMl	
	set @input2=(select top 1 rtrim(@sub) as '@subunitate','RE' as '@tip',
					rtrim(@cont_disp_lei)as '@cont', 
					convert(char(10),@data,101) as '@data',
				
				(select  rtrim(@numar) as '@numar',
					rtrim(@cont_trecere) as '@contcorespondent', 
					(case when @tiptranzactie='CV' then 'PD' else 'ID' end) as '@subtip',
					(case when @cu_dif_curs_cont_valuta=1 then convert(decimal(17,5),@suma_lei_BC) else convert(decimal(17,5),@suma_lei_BNR) end) as '@suma',
					(case when @tiptranzactie='CV' then 'Cumparare valuta' else 'Vanzare valuta' end) as '@explicatii',
					RTRIM(@lm) as '@lm'						 
					for XML path,type)
				for xml Path,type)	 
	--select @input
	exec wScriuPozplin @sesiune,@input2
	
	exec setare_par 'GE','CDISPVAL','Cont disponibil valuta','',0,@cont_disp_valuta
	exec setare_par 'GE','CDISPRON','Cont disponibil RON','',0,@cont_disp_lei
	exec setare_par 'GE','CTRVCVAL','Cont trecere vanz/cump valuta','',0,@cont_trecere
	exec setare_par 'GE','LMVCVAL','Loc munca vanz/cump valuta','',0,@lm	
	
	if isnull(@numar,'')<>'' 
		select 'Operatie efectuata cu succes!!' as textMesaj for xml raw, root('Mesaje')
end try
begin catch
	set @mesaj=ERROR_MESSAGE()
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
--select * from pozdoc where tip='TE' order by data desc
--loc de munca
--suma
--conturile
