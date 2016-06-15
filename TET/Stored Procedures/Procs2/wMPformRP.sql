--***
create procedure [dbo].[wMPformRP] (@term char(8))
as
begin
declare @Sub char(9), @nr char(20), @Data datetime, @Cod char(20), @cant float, @LM char(9), 
	@Com char(20), @Stoc float, @Pret float, @gest char(9), @CantDesc float, @User char(10), 
	@codintr char(13), @Locatie char(30), @Lot char(13), @hostid char(8)
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
set @nr=(select max(numar) from avnefac where terminal=@term and tip='RP')
set @Data=(select max(data) from avnefac where terminal=@term and tip='RP')
if exists (select 1 from sysobjects where [type]='P' and [name]= 'wMPformRPSP')
	exec wMPformRPSP 
else
begin
if not exists(select 1 from doc where tip in ('CM','PP') and numar=@nr and data=@Data) and (select stare from mpdoc where tip in ('RP') and numar=@nr and data=@Data)<>'I'
	begin
		delete from mpdocndpoz where tip in ('CN','PN') and numar=@nr and data=@Data
		insert into MPdocndpoz (Tip, Numar, Data, Schimb, Sarja, Ordonare, Loc_munca, Utilaj, Cod, Intrari, Normat, Efectiv, Stoc, Nr_pozitie, Nr_pozitie_DN, Gestiune, Comanda, Cod_produs, Alfa1, Lot, Locatie, Repartizat, Abateri, cod_parinte, Cod_inlocuit, Nr_mat, Alfa2, Specific, Utilizator, Data_operarii, Ora_operarii, Val1, Val2, Pret, Data_expirarii)
			SELECT 'PN', Numar, Data, Schimb, Sarja, Ordonare, p.Loc_munca, p.Utilaj, a.Cod, 0, a.specific*p.fabricat, a.specific*p.fabricat, 0, Nr_pozitie, ROW_NUMBER() OVER(ORDER BY nr_pozitie), p.Gestiune, (case when a.Comanda<>'' then a.Comanda else p.Comanda end), ''/*p.cod*/, '', Lot, Locatie, 0, 0, '', '', 0, '', 0/*Specific*/, Utilizator, convert(datetime, convert(char(10), getdate(), 104), 104), RTrim(replace(convert(char(8), getdate(), 108), ':', '')), 0, 0, (case when 0=0 then pret when n.pret_stoc=0 then 1 else n.pret_stoc end), Data_expirarii
			from mpdocpoz p left outer join tehnpoz a on a.cod_tehn=p.cod left outer join nomencl n on a.cod=n.cod /*left outer join nomencl nn on a.cod_tehn=nn.cod */
			WHERE p.tip='RP' and numar=@nr and data=@Data and isnull( /*n*/n.um_2,'')<>'Y' and a.tip='R' and a.subtip<>'R'
		exec tehnologii '','Materiale','',0,0,@hostid output,'RP',@nr,@data
		insert into MPdocndpoz (Tip, Numar, Data, Schimb, Sarja, Ordonare, Loc_munca, Utilaj, Cod, Intrari, Normat, Efectiv, Stoc, Nr_pozitie, Nr_pozitie_DN, Gestiune, Comanda, Cod_produs, Alfa1, Lot, Locatie, Repartizat, Abateri, cod_parinte, Cod_inlocuit, Nr_mat, Alfa2, Specific, Utilizator, Data_operarii, Ora_operarii, Val1, Val2, Pret, Data_expirarii)
			SELECT 'CN', p.Numar, p.Data, p.Schimb, p.Sarja, Ordonare, p.Loc_munca, p.Utilaj, a.Cod_material, 0, a.consum_specific*cantitate_neta*p.fabricat, a.consum_specific*cantitate_neta*p.fabricat, 0, Nr_pozitie, ROW_NUMBER() OVER(partition by nr_pozitie ORDER BY nr_pozitie), d.Gest_mat, p.Comanda, ''/*p.cod*/, '', ''/*Lot*/, ''/*Locatie*/, 0, 0, cod_reper, '', 0, '', consum_Specific, p.Utilizator, convert(datetime, convert(char(10), getdate(), 104), 104), RTrim(replace(convert(char(8), getdate(), 108), ':', '')), 0, 0, 0, convert(datetime,'01/01/1901')
			from mpdocpoz p left outer join mpdoc d on p.subunitate=d.subunitate and p.tip=d.tip and p.numar=d.numar and p.data=d.data, tmatprod a --left outer join nomencl n on a.cod=n.cod
			WHERE p.tip='RP' and p.numar=@nr and p.data=@Data and hostid=@hostid and a.cod_produs=p.cod --and isnull( n.um_2,'')<>'Y'

--CM
declare MPtmpmat cursor for
	select cod, sum(efectiv), loc_munca, comanda, gestiune, max(utilizator)
	from mpdocndpoz
	where tip='CN' and numar=@nr and data=@Data 
	group by cod, loc_munca, comanda, gestiune, nr_pozitie having sum(efectiv)>=0.001
open MPtmpmat
fetch next from MPtmpmat into @Cod, @cant, @LM, @com, @Gest, @user
while @@fetch_status=0
begin
	declare MPtmpstoc cursor for
		select cod_intrare, stoc
		from stocuri
		where subunitate=@Sub and tip_gestiune not in ('F', 'T') 
		and cod_gestiune=@Gest and cod=@Cod and stoc>=0.001
		order by data
	open MPtmpstoc
	fetch next from MPtmpstoc into @codintr, @Stoc
	while @cant>0 and @@fetch_status=0
	begin
		set @CantDesc=(case when @stoc<@cant then @stoc else @cant end)
		set @cant=@cant-@CantDesc
		exec scriuCM @nr, @data, @Gest, @Cod, @codintr, @CantDesc, @LM, @Com, '', '', 0, '', @user, 'MPX', 5
		
		fetch next from MPtmpstoc into @codintr, @Stoc
	end
	close MPtmpstoc
	deallocate MPtmpstoc
	if @cant>0
		exec scriuCM @nr, @data, @Gest, @Cod, '', @cant, @LM, @Com, '', '', 0, '', @user, 'MPX', 5
	
	fetch next from MPtmpmat into @Cod, @cant, @LM, @com, @Gest, @user
end
close MPtmpmat
deallocate MPtmpmat

--PP
declare MPtmpprod cursor for
	select cod, efectiv, pret, loc_munca, comanda, gestiune, lot, locatie, utilizator
	from mpdocndpoz
	where tip='PN' and numar=@nr and data=@Data and efectiv>=0.001
open MPtmpprod
fetch next from MPtmpprod into @Cod, @cant, @pret, @LM, @com, @gest, @Lot, @Locatie, @user
while @@fetch_status=0
begin
	--set @Pret=round(convert(decimal(17,5), , 5)
	exec scriuPP @nr, @data, @gest, @Cod, @cant, '', @Pret, '', '', '', 0, @LM, @Com, '', 0, 0, '', @user, 'MPX', 5, @lot
	
	fetch next from MPtmpprod into @Cod, @cant, @pret, @LM, @com, @gest, @Lot, @Locatie, @user
end
close MPtmpprod
deallocate MPtmpprod
update pozdoc set stare=7 where tip in ('CM','PP') and numar=@nr and data=@Data
update doc set stare=7 where tip in ('CM','PP') and numar=@nr and data=@Data
	end

if exists(select name from sysobjects where name='MPformdoc')
	begin
		delete from MPformdoc where terminal=@term
		insert into MPformdoc (Subunitate, Tip, Numar, Data, Schimb, Sarja, Ordonare, Gestiune, Loc_munca, Loc_munca_prim, Utilaj, Utilaj_prim, Comanda, Cod, De_fabricat, Fabricat, Stoc, Predat, Rebut, Rebut_KG, Preluat, Pret, Locatie, Lot, Data_expirarii, tip_consum, Nr_operatie, Cod_operatie, Ora_inceput, Ora_sfarsit, Alfa1, Alfa2, Alfa3, Val1, Val2, Val3, Tip_misc, Nr_pozitie, Utilizator, Data_operarii, Ora_operarii, Jurnal, Serie, Nr_pozitie_serie, Terminal, Ordform)
			select Subunitate, Tip, Numar, Data, Schimb, Sarja, Ordonare, Gestiune, Loc_munca, Loc_munca_prim, Utilaj, Utilaj_prim, Comanda, Cod, De_fabricat, Fabricat, Stoc, Predat, Rebut, Rebut_KG, Preluat, Pret, Locatie, Lot, Data_expirarii, tip_consum, Nr_operatie, Cod_operatie, Ora_inceput, Ora_sfarsit, Alfa1, Alfa2, Alfa3, Val1, Val2, Val3, Tip_misc, Nr_pozitie, Utilizator, Data_operarii, Ora_operarii, Jurnal, '', 0, @term,3 from MPdocpoz p /*, nomencl n */where p.tip='RP' and p.numar=@nr and p.data=@Data --and p.cod=n.cod
	end
else
	begin
		select Subunitate, Tip, Numar, Data, Schimb, Sarja, Ordonare, Gestiune, Loc_munca, Loc_munca_prim, Utilaj, Utilaj_prim, Comanda, Cod, De_fabricat, Fabricat, Stoc, Predat, Rebut, Rebut_KG, Preluat, Pret, Locatie, Lot, Data_expirarii, tip_consum, Nr_operatie, Cod_operatie, Ora_inceput, Ora_sfarsit, Alfa1, Alfa2, Alfa3, Val1, Val2, Val3, Tip_misc, Nr_pozitie, Utilizator, Data_operarii, Ora_operarii, Jurnal, space(20) as Serie, convert(float,'0') as Nr_pozitie_serie, @term as Terminal, convert(float,'3') as Ordform into MPformdoc from MPdocpoz p /*, nomencl n */where p.tip='RP' and p.numar=@nr and p.data=@Data --and p.cod=n.cod
	end

insert into MPformdoc (Subunitate, Tip, Numar, Data, Schimb, Sarja, Ordonare, Gestiune, Loc_munca, Loc_munca_prim, Utilaj, Utilaj_prim, Comanda, Cod, De_fabricat, Fabricat, Stoc, Predat, Rebut, Rebut_KG, Preluat, Pret, Locatie, Lot, Data_expirarii, tip_consum, Nr_operatie, Cod_operatie, Ora_inceput, Ora_sfarsit, Alfa1, Alfa2, Alfa3, Val1, Val2, Val3, Tip_misc, Nr_pozitie, Utilizator, Data_operarii, Ora_operarii, Jurnal, Serie, Nr_pozitie_serie, Terminal, Ordform)
select '','','',getdate(),0,0,0,'','','','','','','Predari:',0,0,0,0,0,0,0,0,'','',getdate(),'',0,'','000000','000000','','','',0,0,0,'',0,'',getdate(),'000000','', '', 0, @term,1
union all 
select '','','',getdate(),0,0,0,'','','','','','','',0,0,0,0,0,0,0,0,'','',getdate(),'',0,'','000000','000000','','','',0,0,0,'',0,'',getdate(),'000000','', '', 0, @term,4
union all 
select '','','',getdate(),0,0,0,'','','','','','','Am predat',0,0,0,0,0,0,0,0,'','',getdate(),'',0,'','000000','000000','','','',0,0,0,'',0,'',getdate(),'000000','', '', 0, @term,5
union all 
select '','','',getdate(),0,0,0,'','','','','','','Sef schimb,',0,0,0,0,0,0,0,0,'','',getdate(),'',0,'','000000','000000','','','',0,0,0,'',0,'',getdate(),'000000','', '', 0, @term,6
union all 
select '','','',getdate(),0,0,0,'','','','','','','',0,0,0,0,0,0,0,0,'','',getdate(),'',0,'','000000','000000','','','',0,0,0,'',0,'',getdate(),'000000','', '', 0, @term,7
union all 
select '','','',getdate(),0,0,0,'','','','','','','Am primit',0,0,0,0,0,0,0,0,'','',getdate(),'',0,'','000000','000000','','','',0,0,0,'',0,'',getdate(),'000000','', '', 0, @term,8
union all 
select '','','',getdate(),0,0,0,'','','','','','','Sef schimb,',0,0,0,0,0,0,0,0,'','',getdate(),'',0,'','000000','000000','','','',0,0,0,'',0,'',getdate(),'000000','', '', 0, @term,9
union all 
select '','','',getdate(),0,0,0,'','','','','','','',0,0,0,0,0,0,0,0,'','',getdate(),'',0,'','000000','000000','','','',0,0,0,'',0,'',getdate(),'000000','', '', 0, @term,10
union all 
select '','','',getdate(),0,0,0,'','','','','','','',0,0,0,0,0,0,0,0,'','',getdate(),'',0,'','000000','000000','','','',0,0,0,'',0,'',getdate(),'000000','', '', 0, @term,11
union all 
select '','','',getdate(),0,0,0,'','','','','','','Consumuri:',0,0,0,0,0,0,0,0,'','',getdate(),'',0,'','000000','000000','','','',0,0,0,'',0,'',getdate(),'000000','', '', 0, @term,12
union all
select '', Tip, Numar, Data, Schimb, Sarja, Ordonare, Gestiune, Loc_munca, '', Utilaj, '', Comanda, Cod, intrari, normat, Stoc, efectiv, 0, 0, 0, Pret, Locatie, Lot, Data_expirarii, '', Nr_mat, '', '', '', Alfa1, Alfa2, '', Val1, Val2, Nr_pozitie_DN, '', Nr_pozitie, Utilizator, Data_operarii, Ora_operarii, 'MPX', '', 0, @term,14 from MPdocndpoz p where p.tip='CN' and p.numar=@nr and p.data=@Data

end
end
