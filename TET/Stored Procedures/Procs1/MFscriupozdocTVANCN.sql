--***
create procedure [dbo].[MFscriupozdocTVANCN] @tip char(2),@subtip char(2),@numar char(8),
@data datetime,@nrinv varchar(13),@contcor varchar(40)='',@contgestprim varchar(40)='',@contlmprim varchar(40)='', 
@contamcomprim varchar(40)='', @indbugprim char(30)='', @gest char(9)=null, @lm char(9)=null,
@com char(20)=null,@indbug char(30)=null,@contmf varchar(40)=null,@conttva varchar(40)='', 
@tipmf int=0,@tert char(13)='',@fact char(20)='',@datafact datetime='01/01/1901',
@datascad datetime='01/01/1901',@valinv float=0,@valam float=0,@valamcls8 float=0,@valamneded float=0,
@rezreev float=0, @cotatva float=0, @sumatva float=0, @tiptva int=0, @difvalinv float=0, @pret float=0,
@ajust float=0, @pretvaluta float=0, @valuta char(3)='', @curs float=0, @cod char(20)='MIJLOC_FIX_MF'
as
declare @sub char(9),@cttvaded varchar(40), @contTVANCN varchar(40), 
	@userASiS varchar(10), @stare int, @jurnal char(3), @nrpozitie int, @nrpozitiem int,
	@datal datetime,@tipdocCG char(2),@tipm char(2),@subtipm char(2),@pretm float,@ctamm varchar(40),
	@ctrezreev varchar(40),@amlun float,@amluncls8 float,@binar varbinary(128)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
exec luare_date_par 'GE', 'CDTVA', 0, 0, @cttvaded output
set @contTVANCN=ISNULL((select cont from nomencl where cod='TVANCN'),'635')
set @userASiS = isnull(dbo.fIaUtilizator(null),'')
--select @tip='MI', @subtip='AF'
select @tipm=@tip, @subtipm=@subtip, @datal=dbo.EOM(@data), @stare=2/*7*/, --@cod='TVANCN', 
	@jurnal='MFX' /*nu schimba jurnalul!!!!!*/

set @binar=cast('modificaredocdefinitivMF' as varbinary(128))
set CONTEXT_INFO @binar

SET @tipdocCG=(case @tip when 'MI' then (case @subtip when 'AF' then 'RM' else 'AI' end) 
			when 'MM' then (case @subtip when 'EP' then 'AE' when 'FF' then 'RM' else 'AI' end) 
			when 'ME' then (case @subtip when 'SU' then 'AE' when 'VI' then 'AP' else 'AE' end) 
			when 'MT' then (case when 6/*@procinch*/=6 and @subtip='SE' then 'AI' else '' end) 
			else '' end)
IF @tip in ('MI','MM','ME','MT') DELETE pozdoc where subunitate=@sub and tip=@tipdocCG 
	and numar=@Numar and data=@Data and cod='TVANCN' and Cod_intrare=@nrinv and Jurnal=@jurnal --and Numar_pozitie=@nrpozitie
IF @tip in ('MI','MM','ME','MT') and 6/*@procinch*/=6 --and @subtip='AF'
BEGIN
		IF isnull(@nrpozitie,0)=0 
		begin
			EXEC luare_date_par 'DO','POZITIE',0,@nrpozitie output,''
			SET @nrpozitie=(case when isnull(@nrpozitie,0)>=999999998 then 0 else 
				isnull(@nrpozitie,0) end)+1
			SET @nrpozitiem=@nrpozitie+(case when @tip='MT' then 1 else 0 end)
			EXEC setare_par 'DO','POZITIE',null,null,@nrpozitiem,null 
		end
 
		IF @tipm='MI' INSERT pozdoc
			(Subunitate,Tip,Numar,Cod,Data,Gestiune,Cantitate,Pret_valuta,Pret_de_stoc,Adaos,
			Pret_vanzare,Pret_cu_amanuntul,TVA_deductibil,Cota_TVA,Utilizator,Data_operarii,
			Ora_operarii,Cod_intrare,Cont_de_stoc,Cont_corespondent,TVA_neexigibil,
			Pret_amanunt_predator,Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,Loc_de_munca,
			Comanda,Barcod,Cont_intermediar,Cont_venituri,Discount,Tert,Factura,
			Gestiune_primitoare,Numar_DVI,Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,
			Data_scadentei,Procent_vama,Suprataxe_vama,Accize_cumparare,Accize_datorate,
			Contract,Jurnal)
			VALUES 
			(@sub,@tipdocCG,@Numar,'TVANCN',@Data,@Gest,1,0,0,0,0,
			0,@sumatva,@cotatva,@userASiS,convert(datetime,convert(char(10),getdate(),104),104), 
			RTrim(replace(convert(char(8),getdate(),108),':','')),@nrinv,(case when @tiptva=5 then @contmf else @contTVANCN end),'',
			0,0,'V','',@data,@nrpozitie,@lm,@com+replace(@indbug,'.',''),'','',
			(case when @conttva='' then @cttvaded else @conttva end),
			0, @tert,@fact,'','',@Stare,(case when @subtipm='AF' and @valuta<>'' 
			then rtrim(convert(char(20),convert(decimal(14,2),1.00*@sumatva/@curs))) else '' end), 
			@contcor,@Valuta,@Curs,@Datafact,@Datascad,3,
			0,0,0,(case @subtipm when 'AF' then right(@tip,1)+@subtip else '' end),@Jurnal)
END
set CONTEXT_INFO 0x00
