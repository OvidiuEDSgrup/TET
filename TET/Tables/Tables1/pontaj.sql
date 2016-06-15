CREATE TABLE [dbo].[pontaj] (
    [Data]                           DATETIME   NOT NULL,
    [Marca]                          CHAR (6)   NOT NULL,
    [Numar_curent]                   SMALLINT   NOT NULL,
    [Loc_de_munca]                   CHAR (9)   NOT NULL,
    [Loc_munca_pentru_stat_de_plata] BIT        NOT NULL,
    [Tip_salarizare]                 CHAR (1)   NOT NULL,
    [Regim_de_lucru]                 REAL       NOT NULL,
    [Salar_orar]                     FLOAT (53) NOT NULL,
    [Ore_lucrate]                    SMALLINT   NOT NULL,
    [Ore_regie]                      SMALLINT   NOT NULL,
    [Ore_acord]                      SMALLINT   NOT NULL,
    [Ore_suplimentare_1]             SMALLINT   NOT NULL,
    [Ore_suplimentare_2]             SMALLINT   NOT NULL,
    [Ore_suplimentare_3]             SMALLINT   NOT NULL,
    [Ore_suplimentare_4]             SMALLINT   NOT NULL,
    [Ore_spor_100]                   SMALLINT   NOT NULL,
    [Ore_de_noapte]                  SMALLINT   NOT NULL,
    [Ore_intrerupere_tehnologica]    SMALLINT   NOT NULL,
    [Ore_concediu_de_odihna]         SMALLINT   NOT NULL,
    [Ore_concediu_medical]           SMALLINT   NOT NULL,
    [Ore_invoiri]                    SMALLINT   NOT NULL,
    [Ore_nemotivate]                 SMALLINT   NOT NULL,
    [Ore_obligatii_cetatenesti]      SMALLINT   NOT NULL,
    [Ore_concediu_fara_salar]        SMALLINT   NOT NULL,
    [Ore_donare_sange]               SMALLINT   NOT NULL,
    [Salar_categoria_lucrarii]       FLOAT (53) NOT NULL,
    [Coeficient_acord]               FLOAT (53) NOT NULL,
    [Realizat]                       FLOAT (53) NOT NULL,
    [Coeficient_de_timp]             FLOAT (53) NOT NULL,
    [Ore_realizate_acord]            REAL       NOT NULL,
    [Sistematic_peste_program]       REAL       NOT NULL,
    [Ore_sistematic_peste_program]   SMALLINT   NOT NULL,
    [Spor_specific]                  FLOAT (53) NOT NULL,
    [Spor_conditii_1]                FLOAT (53) NOT NULL,
    [Spor_conditii_2]                FLOAT (53) NOT NULL,
    [Spor_conditii_3]                FLOAT (53) NOT NULL,
    [Spor_conditii_4]                FLOAT (53) NOT NULL,
    [Spor_conditii_5]                FLOAT (53) NOT NULL,
    [Spor_conditii_6]                FLOAT (53) NOT NULL,
    [Ore__cond_1]                    SMALLINT   NOT NULL,
    [Ore__cond_2]                    SMALLINT   NOT NULL,
    [Ore__cond_3]                    SMALLINT   NOT NULL,
    [Ore__cond_4]                    SMALLINT   NOT NULL,
    [Ore__cond_5]                    SMALLINT   NOT NULL,
    [Ore__cond_6]                    REAL       NOT NULL,
    [Grupa_de_munca]                 CHAR (1)   NOT NULL,
    [Ore]                            SMALLINT   NOT NULL,
    [Spor_cond_7]                    FLOAT (53) NOT NULL,
    [Spor_cond_8]                    FLOAT (53) NOT NULL,
    [Spor_cond_9]                    FLOAT (53) NOT NULL,
    [Spor_cond_10]                   FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[pontaj]([Data] ASC, [Marca] ASC, [Numar_curent] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Marca]
    ON [dbo].[pontaj]([Marca] ASC, [Data] ASC, [Numar_curent] ASC);


GO
--***
create trigger tr_ValidPontaj on pontaj for insert,update,delete NOT FOR REPLICATION as
DECLARE @nrRanduri int, @mesaj varchar(255), @mesajeroare varchar(255)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try	
	declare @userASiS varchar(50)
	set @userASiS=dbo.fIaUtilizator(null)

	/** Validare luna inchisa/blocata Salarii */
	create table #lunasalarii (data datetime, nume_tabela varchar(50))
	insert into #lunasalarii (data, nume_tabela)
	select DISTINCT Data, 'PONTAJ' from inserted
	union all
	select DISTINCT Data, 'PONTAJ' from deleted
	exec validLunaInchisaSalarii

	/* Validare marca */
	if UPDATE(Marca) 
	begin
		create table #marci (marca varchar(20), data datetime)
		insert into #marci (marca, data)
		select marca, dbo.BOM(data) from INSERTED 
		exec validMarcaSalarii
	end 

	/* Validare loc de munca */
	if UPDATE(Loc_de_munca) 
	begin
		create table #lm(utilizator varchar(50),cod varchar(20),data datetime)
		insert into #lm(utilizator,cod,data)
		select distinct @userASiS,loc_de_munca,data from inserted		
		exec validLMSalarii

		declare @SalariatiPeComenzi int
		set @SalariatiPeComenzi=dbo.iauParL('PS','SALCOM')
		if @SalariatiPeComenzi=0 
			and exists (select 1 from pontaj p inner join inserted i on i.Data=p.Data and i.Marca=p.Marca and i.Loc_de_munca=p.Loc_de_munca and i.Numar_curent<>p.Numar_curent)
				raiserror('Eroare operare: Exista deja pontaj pentru marca, data si loc de munca introduse!',16,1)
	end 

	if UPDATE(Regim_de_lucru) --Verificam consistenta regimului de lucru
	begin
		if exists (select 1 from inserted i where Regim_de_lucru=0)
			raiserror('Eroare operare: Regim de lucru 0 nepermis in pontaj!',16,1)
	end 

	if UPDATE(Spor_cond_10) --Verificam consistenta orelor de delegatie
	begin
		if exists (select 1 from inserted i where Spor_cond_10<>0 and convert(decimal(10,2),Spor_cond_10)%convert(decimal(10,2),Regim_de_lucru)<>0)
			raiserror('Eroare operare: Orele de delegatie nu sunt multimplu ale regimului de lucru!',16,1)
	end 

	if UPDATE(Ore_concediu_de_odihna) --Verificam consistenta orelor de concediu de odihna
	begin
		if exists (select 1 from inserted i where Ore_concediu_de_odihna>dbo.zile_lucratoare(dbo.BOM(i.Data),dbo.EOM(i.Data))*i.Regim_de_lucru)
		begin
			select @mesajeroare='Eroare operare: La salariatul '+rtrim(p.Nume)+' marca ('+rtrim(i.Marca)+'), numarul de ore de concediu de odihna depaseste numarul de ore lucratoare in luna!'
					from inserted i 
						left outer join personal p on p.Marca=i.Marca
					where Ore_concediu_de_odihna>dbo.zile_lucratoare(dbo.BOM(i.Data),dbo.EOM(i.Data))*i.Regim_de_lucru
			raiserror(@mesajeroare,16,1)
		end	
	end 
end try

begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()+' (tr_ValidPontaj)'
	raiserror(@mesaj, 11, 1)
	RETURN
end catch

GO
--***
CREATE trigger pontajsterg on pontaj for insert,update, delete  NOT FOR REPLICATION as
begin

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

    insert into sysspon
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator, 
	  'A', Data, Marca, Numar_curent, Loc_de_munca, Loc_munca_pentru_stat_de_plata, Tip_salarizare, Regim_de_lucru,          
      Salar_orar, Ore_lucrate, Ore_regie, Ore_acord, Ore_suplimentare_1, Ore_suplimentare_2, Ore_suplimentare_3, Ore_suplimentare_4,          
      Ore_spor_100, Ore_de_noapte, Ore_intrerupere_tehnologica, Ore_concediu_de_odihna, Ore_concediu_medical,          
      Ore_invoiri, Ore_nemotivate, Ore_obligatii_cetatenesti, Ore_concediu_fara_salar, Ore_donare_sange,          
      Salar_categoria_lucrarii, Coeficient_acord, Realizat, Coeficient_de_timp, Ore_realizate_acord, Sistematic_peste_program,          
      Ore_sistematic_peste_program, Spor_specific, Spor_conditii_1, Spor_conditii_2, Spor_conditii_3, Spor_conditii_4, Spor_conditii_5,          
      Spor_conditii_6, Ore__cond_1, Ore__cond_2, Ore__cond_3, Ore__cond_4, Ore__cond_5, Ore__cond_6, Grupa_de_munca, Ore, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10
   from inserted 
insert into sysspon
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator, 
	  'S', Data, Marca, Numar_curent, Loc_de_munca, Loc_munca_pentru_stat_de_plata, Tip_salarizare, Regim_de_lucru,          
      Salar_orar, Ore_lucrate, Ore_regie, Ore_acord, Ore_suplimentare_1, Ore_suplimentare_2, Ore_suplimentare_3, Ore_suplimentare_4,          
      Ore_spor_100, Ore_de_noapte, Ore_intrerupere_tehnologica, Ore_concediu_de_odihna, Ore_concediu_medical,          
      Ore_invoiri, Ore_nemotivate, Ore_obligatii_cetatenesti, Ore_concediu_fara_salar, Ore_donare_sange,          
      Salar_categoria_lucrarii, Coeficient_acord, Realizat, Coeficient_de_timp, Ore_realizate_acord, Sistematic_peste_program,          
      Ore_sistematic_peste_program, Spor_specific, Spor_conditii_1, Spor_conditii_2, Spor_conditii_3, Spor_conditii_4, Spor_conditii_5,          
      Spor_conditii_6, Ore__cond_1, Ore__cond_2, Ore__cond_3, Ore__cond_4, Ore__cond_5, Ore__cond_6, Grupa_de_munca, Ore, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10
   from deleted  
end
