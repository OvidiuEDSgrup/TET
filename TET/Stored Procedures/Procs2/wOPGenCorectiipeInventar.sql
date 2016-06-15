create procedure wOPGenCorectiipeInventar @sesiune varchar(50), @parXML xml
as
-- Ghita, 03.05.2012:
-- prezenta procedura ar trebui sa ia stoc faptoc cu functia fStocuriCen, la data inventarului 
-- ar mai trebui sa interpreteze separat plusuri si minusuri de inventar 
-- aparent, mai jos este tratata doar partea de lucru pe serii si nici asta bine
-- => nu folositi aceasta procedura!
declare @stergcorectii bit, @gencorectii bit, @intrari varchar(20), @iesiri varchar(20), @contcoresp varchar(40), @gestiune varchar(20),
		@nrdoc varchar(20), @datadoc datetime, @userASiS varchar(20), @msgEroare varchar(20), @datainv datetime,
		@denumire varchar(20), @stocfaptic float, @stocscriptic float, @sub int, @cod varchar(20), @codi varchar(20),
		@pretstoc varchar(20), @data_operarii datetime, @ora_operarii varchar(20), @contstoc varchar(40), @nrpoz varchar(20),@pretaman float,
		@serie int, @stfaptsr float,@stfaptinvsr float, @stscriptpdsr float,@tip varchar(2),@corectsr int,@corectinv int,@fetchcrsinventar int,
		@cantitate float, @cantitateAI float, @cantitateAE float, @pretvaluta float, @inwhile int, @tabelaPreturi int, @actNomlaOpIntrari int
select @stergcorectii=ISNULL(@parXML.value('(/parametri/@stergcorectii)[1]', 'bit'), ''),
       @gencorectii=ISNULL(@parXML.value('(/parametri/@gencorectii)[1]', 'bit'), ''),
	   @contcoresp=ISNULL(@parXML.value('(/parametri/@contcor)[1]', 'varchar(40)'), ''),
	   @gestiune=ISNULL(@parXML.value('(/parametri/@gest)[1]', 'varchar(20)'), ''),
	   @nrdoc=ISNULL(@parXML.value('(/parametri/@nrdoc)[1]', 'varchar(20)'), ''),
	   @datadoc=ISNULL(@parXML.value('(/parametri/@datadoc)[1]', 'datetime'), '2900-01-01'),
	   @datainv=ISNULL(@parXML.value('(/parametri/@datainv)[1]', 'datetime'), '2900-01-01')
begin try
set @inwhile=0
set @corectinv=0
set @corectsr=0
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
exec luare_date_par 'GE', 'PRETURI', 0, 0, @tabelaPreturi output -- setare pentru pret stoc
exec luare_date_par 'GE', 'ACTNOMINT', 0, 0, @actNomlaOpIntrari output --setare pentru pret amanunt
if substring(@contcoresp,1,1) not in ('6','7') 
    raiserror('Corectia se face print conturile care incep cu 6/7 - Cheltuieli/Venituri! Selectati un cont corespunzator!',16,1)
if @stergcorectii=0 and @gencorectii=1
begin
	set @msgEroare='Nu se poate rula generarea de corectii din inventar, daca nu bifati si stergerea corectiilor existente.'
	raiserror (@msgEroare,11,1)
end
if @stergcorectii=1
begin
  delete from doc where Numar=@nrdoc and data=@datainv and cod_Gestiune=@gestiune 
  delete from pozdoc where Numar=@nrdoc and data=@datainv and Gestiune=@gestiune 
  delete from pdserii where Numar=@nrdoc and data=@datainv and Gestiune=@gestiune 
end
if @gencorectii=1
begin
  ------------------------------------ cursor pe inventar------------------------------------------
  declare crsinventar cursor for
  select  rtrim(iv.Cod_produs), rtrim(invsr.Stoc_faptic), rtrim(rm.Cantitate), rtrim(rm.numar_pozitie) ,rtrim(s.pret), s.cont,s.cod_intrare, 
		n.pret_stoc, n.pret_in_valuta, s.pret_cu_amanuntul, invsr.Serie
		from inventar iv
		inner join nomencl n on Cod_produs=n.Cod and iv.Gestiunea=@gestiune and iv.Data_inventarului=@datainv
		inner join stocuri s on s.Subunitate=iv.subunitate and s.Cod=iv.cod_produs and s.cod_gestiune=iv.gestiunea and s.stoc>0
		inner join invserii invsr on iv.Subunitate=invsr.Subunitate and iv.Data_inventarului=invsr.Data_inventarului 
										and iv.Gestiunea=invsr.Gestiunea and invsr.Stoc_faptic>0
		inner join pdserii rm on rm.Subunitate=iv.Subunitate and rm.Gestiune=iv.Gestiunea 
									and rm.cod=iv.Cod_produs and rm.serie=invsr.Serie and rm.Tip='RM'   
    open crsinventar
	fetch next from crsinventar into @cod, @stocfaptic, @stocscriptic, @nrpoz,
									 @pretstoc, @contstoc, @codi, @pretstoc, @pretvaluta, @pretaman,@serie
	while @@FETCH_STATUS= 0
	begin
	  set @inwhile=@inwhile+1
	  set @tip=(case when @stocfaptic>@stocscriptic then 'AI' else 'AE' end)
	  set @cantitateAE=@stocscriptic-@stocfaptic
	  set @cantitateAI=@stocfaptic-@stocscriptic
      select @cantitate=isnull((case when @tip='AI' then @cantitateAI else @cantitateAE  end ),'')
	  set @cantitate=convert(decimal(12,2),@cantitate)
	  set @pretaman=(case when @tabelaPreturi=0 then 
					(select pret_vanzare from preturi where um='1' and cod_produs=@cod and getdate()<=data_superioara and getdate()>=data_inferioara )
						else @pretaman end)
	 --insert into pozdoc
      --   values (@sub, @tip,@nrdoc,@cod,@datadoc,@gestiune,
			--   '',0,@pretstoc,
			--   0,0,@pretaman,0,0,@userASiS,@data_operarii,@ora_operarii, @codi, 
			--   @contstoc,@contcoresp,0,0,'E','','1901-01-01',@nrpoz,'','','','','',0,'','','','',3,'','','',0,convert(datetime,'1901-01-01',103),
			--   convert(datetime,'1901-01-01',103),
			--   0,0,0,0,'','')
			 --set @stfaptinvsr=(select invsr.Stoc_faptic	 from invserii invsr
	   --                          inner join pdserii ps on invsr.subunitate=ps.subunitate and invsr.gestiunea=ps.gestiune and invsr.cod_produs=ps.cod 
				--	             and invsr.serie= ps.serie and invsr.gestiunea=@gestiune and invsr.data_inventarului=@datainv and stoc_faptic>0
				--			     and ps.tip='RM' and invsr.serie=@serie)
    --         set @stscriptpdsr=(select  ps.cantitate from invserii invsr
	   --                          inner join pdserii ps on invsr.subunitate=ps.subunitate and invsr.gestiunea=ps.gestiune and invsr.cod_produs=ps.cod 
				--	             and invsr.serie= ps.serie and invsr.gestiunea=@gestiune and invsr.data_inventarului=@datainv and stoc_faptic>0
				--			     and ps.tip='RM' and invsr.serie=@serie)
				
declare @input xml
	set @input=(select top 1 rtrim(@sub) as '@subunitate',@tip as '@tip' ,
	@nrdoc as '@numar', convert(varchar(20),@datadoc,101) as '@data', 
	@gestiune as '@gestiune',
	(select  rtrim(@pretvaluta) as '@pvalutaS',rtrim(@pretstoc) as '@pstocS',
			 rtrim(@nrpoz) as '@numarpozitie',rtrim(@cod) as '@cod',rtrim(@codi) as '@codintrare' for xml path('linie'),type),
	(select 'SE' as '@subtip', convert(varchar(20),@pretaman)  as '@pamanunt',
			 rtrim(@cod) as '@cod' ,convert(varchar(20),@cantitate) as '@cantitate',
			 @serie as '@serie',rtrim(@codi) as '@codintrare',@nrdoc as '@contract'
	for XML path,type)
	for XML path,type)
	select @input
	exec wScriuPozdoc @sesiune,@input
	--     insert into pdserii
	--values(@sub,@tip,@nrdoc,@datainv,@gestiune,@cod,@codi,@serie,
	--(case when @tip='AI'then @stfaptinvsr-@stscriptpdsr else @stscriptpdsr-@stfaptinvsr end),'E',@nrpoz,'')
	fetch next from crsinventar into @cod, @stocfaptic, @stocscriptic, @nrpoz,
									 @pretstoc, @contstoc, @codi, @pretstoc, @pretvaluta, @pretaman,@serie
	end
	-------------------------- sf cursor pe inventar---------------------------------------
		begin try 
		close crsinventar 
		
	end try 
	begin catch end catch
	begin try 
        deallocate crsinventar
	end try 
	begin catch end catch
end
  if @inwhile=0
	select 'Nu s-au generat corectii!Nu exista stoc pentru pozitiile inventarului!'as textMesaj for xml raw, root('Mesaje')
  else	
	select 'Generare corectii efectuat cu succes! S-a generat documentul de tip:'
	             +case when @stocfaptic>@stocscriptic then 'AI' else 'AE' end +' cu numarul:'+@nrdoc as textMesaj for xml raw, root('Mesaje')
end try  
begin catch  
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch

if exists (select * from sysobjects where name='wOPGenCorectiipeInventar')
drop procedure wOPGenCorectiipeInventar
