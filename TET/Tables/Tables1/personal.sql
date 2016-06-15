CREATE TABLE [dbo].[personal] (
    [Marca]                         CHAR (6)     NOT NULL,
    [Nume]                          CHAR (50)    NOT NULL,
    [Cod_functie]                   CHAR (6)     NOT NULL,
    [Loc_de_munca]                  CHAR (9)     NOT NULL,
    [Loc_de_munca_din_pontaj]       BIT          NOT NULL,
    [Categoria_salarizare]          CHAR (4)     NOT NULL,
    [Grupa_de_munca]                CHAR (1)     NOT NULL,
    [Salar_de_incadrare]            FLOAT (53)   NOT NULL,
    [Salar_de_baza]                 FLOAT (53)   NOT NULL,
    [Salar_orar]                    FLOAT (53)   NOT NULL,
    [Tip_salarizare]                CHAR (1)     NOT NULL,
    [Tip_impozitare]                CHAR (1)     NOT NULL,
    [Pensie_suplimentara]           SMALLINT     NOT NULL,
    [Somaj_1]                       SMALLINT     NOT NULL,
    [As_sanatate]                   SMALLINT     NOT NULL,
    [Indemnizatia_de_conducere]     FLOAT (53)   NOT NULL,
    [Spor_vechime]                  REAL         NOT NULL,
    [Spor_de_noapte]                REAL         NOT NULL,
    [Spor_sistematic_peste_program] REAL         NOT NULL,
    [Spor_de_functie_suplimentara]  FLOAT (53)   NOT NULL,
    [Spor_specific]                 FLOAT (53)   NOT NULL,
    [Spor_conditii_1]               FLOAT (53)   NOT NULL,
    [Spor_conditii_2]               FLOAT (53)   NOT NULL,
    [Spor_conditii_3]               FLOAT (53)   NOT NULL,
    [Spor_conditii_4]               FLOAT (53)   NOT NULL,
    [Spor_conditii_5]               FLOAT (53)   NOT NULL,
    [Spor_conditii_6]               FLOAT (53)   NOT NULL,
    [Sindicalist]                   BIT          NOT NULL,
    [Salar_lunar_de_baza]           FLOAT (53)   NOT NULL,
    [Zile_concediu_de_odihna_an]    SMALLINT     NOT NULL,
    [Zile_concediu_efectuat_an]     SMALLINT     NOT NULL,
    [Zile_absente_an]               SMALLINT     NOT NULL,
    [Vechime_totala]                DATETIME     NOT NULL,
    [Data_angajarii_in_unitate]     DATETIME     NOT NULL,
    [Banca]                         CHAR (25)    NOT NULL,
    [Cont_in_banca]                 CHAR (25)    NOT NULL,
    [Poza]                          IMAGE        NULL,
    [Sex]                           BIT          NOT NULL,
    [Data_nasterii]                 DATETIME     NOT NULL,
    [Cod_numeric_personal]          CHAR (13)    NOT NULL,
    [Studii]                        CHAR (10)    NOT NULL,
    [Profesia]                      CHAR (10)    NOT NULL,
    [Adresa]                        CHAR (30)    NOT NULL,
    [Copii]                         CHAR (30)    NOT NULL,
    [Loc_ramas_vacant]              BIT          NOT NULL,
    [Localitate]                    CHAR (30)    NOT NULL,
    [Judet]                         CHAR (15)    NOT NULL,
    [Strada]                        CHAR (25)    NOT NULL,
    [Numar]                         CHAR (5)     NOT NULL,
    [Cod_postal]                    INT          NOT NULL,
    [Bloc]                          CHAR (10)    NOT NULL,
    [Scara]                         CHAR (2)     NOT NULL,
    [Etaj]                          CHAR (2)     NOT NULL,
    [Apartament]                    CHAR (5)     NOT NULL,
    [Sector]                        SMALLINT     NOT NULL,
    [Mod_angajare]                  CHAR (1)     NOT NULL,
    [Data_plec]                     DATETIME     NOT NULL,
    [Tip_colab]                     CHAR (3)     NOT NULL,
    [grad_invalid]                  CHAR (1)     NOT NULL,
    [coef_invalid]                  REAL         NOT NULL,
    [alte_surse]                    BIT          NOT NULL,
    [fictiv]                        INT          NULL,
    [detalii]                       XML          NULL,
    [Activitate]                    VARCHAR (10) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Marca]
    ON [dbo].[personal]([Marca] ASC);


GO
CREATE NONCLUSTERED INDEX [Nume]
    ON [dbo].[personal]([Nume] ASC);


GO
--***
CREATE trigger personalsterg on personal for update, delete  NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysss
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	Marca, Nume, Cod_functie, Loc_de_munca, Loc_de_munca_din_pontaj, Categoria_salarizare, Grupa_de_munca,
	Salar_de_incadrare, Salar_de_baza, Salar_orar, Tip_salarizare, Tip_impozitare, Pensie_suplimentara, Somaj_1,
	As_sanatate, Indemnizatia_de_conducere, Spor_vechime, Spor_de_noapte, Spor_sistematic_peste_program, 
	Spor_de_functie_suplimentara, Spor_specific, Spor_conditii_1, Spor_conditii_2, Spor_conditii_3, Spor_conditii_4,
	Spor_conditii_5, Spor_conditii_6, Sindicalist, Salar_lunar_de_baza, Zile_concediu_de_odihna_an, 
	Zile_concediu_efectuat_an, Zile_absente_an, Vechime_totala, Data_angajarii_in_unitate, Banca, Cont_in_banca, 
	Sex, Data_nasterii, Cod_numeric_personal, Studii, Profesia, Adresa, Copii, Loc_ramas_vacant, Localitate,
	Judet, Strada, Numar, Cod_postal, Bloc, Scara, Etaj, Apartament, Sector, Mod_angajare, Data_plec, Tip_colab,
	grad_invalid, coef_invalid, alte_surse
   from deleted

GO
--***
create  trigger tr_validPersonal on personal for insert, update NOT FOR REPLICATION as
DECLARE @nrRanduri int, @mesaj varchar(255), @categsal int, @NCAnActiv int, @Somesana int
SET @nrRanduri=@@ROWCOUNT
set @Somesana=dbo.iauParL('SP','SOMESANA')
IF @nrRanduri=0 
	RETURN

begin try
	declare @userASiS varchar(50)
	set @userASiS=dbo.fIaUtilizator(null)

	if UPDATE(Cod_functie) --Verificam consistenta codului de functie
	begin
		if not exists (select 1 from inserted i inner join functii f on i.Cod_functie=f.Cod_functie)
			raiserror('Eroare operare: Cod functie neintrodus sau inexistent in catalogul de functii!',16,1)
	end 

	/* Validare loc de munca */
	if UPDATE(Loc_de_munca) and @Somesana=0 
	begin
		create table #lm(utilizator varchar(50),cod varchar(20),data datetime)
		insert into #lm(utilizator,cod,data)
		select distinct @userASiS,loc_de_munca, convert(datetime,convert(char(10),getdate(),101),101) from inserted		
		exec validLMSalarii
	end 

	if UPDATE(Categoria_salarizare) --Verificam consistenta categoriei de salarizare
	begin
		exec luare_date_par 'PS', 'CATEGSAL', @categsal output, 0, ''

		if @categsal=1 and not exists (select 1 from inserted i inner join categs cs on i.Categoria_salarizare=cs.Categoria_salarizare)
			raiserror('Eroare operare: Categorie de salarizare neintrodusa sau inexistenta in catalogul de categorii!',16,1)
	end 

	if UPDATE(Activitate) --Verificam consistenta campului activitate
	begin
		exec luare_date_par 'PS', 'N-C-A-ACT', @NCAnActiv output, 0, ''

		if @NCAnActiv=1 and exists (select 1 from inserted where nullif(Activitate,'') is null)
		begin
			select top 1 @mesaj='Eroare operare: Salariatul ('+rtrim(Nume)+') nu are completata activitatea!'
			from inserted where nullif(Activitate,'') is null
			raiserror(@mesaj,16,1)
		end
	end 

	if UPDATE(Grupa_de_munca) or UPDATE(Salar_lunar_de_baza) --Verificam corelarea intre grupa de munca si regimul de lucru pt. cei cu contract de munca cu timp partial
	begin
		if exists (select 1 from inserted where Grupa_de_munca='C' and Salar_lunar_de_baza=0)
		begin
			select @mesaj='Eroare operare: Pentru un salariat ('+rtrim(Nume)+') cu contract de munca cu timp partial trebuie introdus regimul de lucru!'
			from inserted where Grupa_de_munca='C' and Salar_lunar_de_baza=0
			raiserror(@mesaj,16,1)
		end
			
		if exists (select 1 from inserted where Grupa_de_munca in ('N','D','S') and Salar_lunar_de_baza>0 and Salar_lunar_de_baza<6)
		begin
			select @mesaj='Eroare operare: Un salariat ('+rtrim(Nume)+') cu regim de lucru mai mic de 6 ore/zi trebuie incadrat pe conditii de munca C-contract de munca cu timp partial!'
			from inserted where Grupa_de_munca in ('N','D','S') and Salar_lunar_de_baza>0 and Salar_lunar_de_baza<6
			raiserror(@mesaj,16,1)
		end	

		if exists (select 1 from inserted where Grupa_de_munca='C' and Salar_lunar_de_baza=8)
		begin
			select @mesaj='Eroare operare: Un salariat ('+rtrim(Nume)+') cu contract de munca cu timp partial nu poate avea un regim de lucru de 8 ore/zi!'
			from inserted where Grupa_de_munca='C' and Salar_lunar_de_baza=8
			raiserror(@mesaj,16,1)
		end	
	end	
--	Verificam durata contractului de munca pe perioada determinata (sa nu fie mai mare de 36 de luni)
	if UPDATE(Data_plec)
	Begin
		if exists (select 1 from inserted where Mod_angajare='D' and convert(int,Loc_ramas_vacant)=0 and CHARINDEX(Grupa_de_munca,'OP')=0
			and DATEDIFF(day,Data_angajarii_in_unitate,Data_plec)>365*3)
				raiserror('Eroare operare: Contractul individual de munca pe durata determinata nu poate fi incheiat pe o perioada mai mare de 36 de luni!',16,1)
	End		
--	Verificam existenta de date lunare pe luna ulterioara lunii de plecare
	if UPDATE(Loc_ramas_vacant) or UPDATE(Data_plec)
	begin
		if exists (select 1 from inserted where convert(int,Loc_ramas_vacant)=1 and Data_plec not in ('01/01/1901','01/01/1900'))
		Begin
			if exists (select 1 from pontaj p inner join inserted i on i.Marca=p.Marca 
				where convert(int,Loc_ramas_vacant)=1 and Data_plec not in ('01/01/1901','01/01/1900') and dbo.eom(p.Data)>dbo.EOM(i.Data_plec))
			Begin
				select @mesaj='Eroare operare: Salariatul '+rtrim(i.Nume)+' marca ('+rtrim(i.Marca)+') are pontaje pe luna ulterioara lunii de plecare !'
				from pontaj p inner join inserted i on i.Marca=p.Marca 
				where convert(int,Loc_ramas_vacant)=1 and Data_plec not in ('01/01/1901','01/01/1900') and dbo.eom(p.Data)>dbo.EOM(i.Data_plec)
				raiserror(@mesaj,16,1)
			End
			if exists (select 1 from ConcOdih co inner join inserted i on i.Marca=co.Marca 
				where convert(int,Loc_ramas_vacant)=1 and Data_plec not in ('01/01/1901','01/01/1900') and co.Data>dbo.EOM(i.Data_plec))
			Begin
				select @mesaj='Eroare operare: Salariatul '+rtrim(i.Nume)+' marca ('+rtrim(i.Marca)+') are concedii de odihna pe luna ulterioara lunii de plecare !'
				from ConcOdih co inner join inserted i on i.Marca=co.Marca 
				where convert(int,Loc_ramas_vacant)=1 and Data_plec not in ('01/01/1901','01/01/1900') and co.Data>dbo.EOM(i.Data_plec)
				raiserror(@mesaj,16,1)
			End
			if exists (select 1 from conmed cm inner join inserted i on i.Marca=cm.Marca 
				where convert(int,Loc_ramas_vacant)=1 and Data_plec not in ('01/01/1901','01/01/1900') and cm.Data>dbo.EOM(i.Data_plec))
			Begin
				select @mesaj='Eroare operare: Salariatul '+rtrim(i.Nume)+' marca ('+rtrim(i.Marca)+') are concedii medicale pe luna ulterioara lunii de plecare !'
				from conmed cm inner join inserted i on i.Marca=cm.Marca 
				where convert(int,Loc_ramas_vacant)=1 and Data_plec not in ('01/01/1901','01/01/1900') and cm.Data>dbo.EOM(i.Data_plec)
				raiserror(@mesaj,16,1)
			End	
			if exists (select 1 from avexcep a inner join inserted i on i.Marca=a.Marca 
				where convert(int,Loc_ramas_vacant)=1 and Data_plec not in ('01/01/1901','01/01/1900') and a.Data>dbo.EOM(i.Data_plec))
			Begin
				select @mesaj='Eroare operare: Salariatul '+rtrim(i.Nume)+' marca ('+rtrim(i.Marca)+') are avans exceptie pe luna ulterioara lunii de plecare !'
				from avexcep a inner join inserted i on i.Marca=a.Marca 
				where convert(int,Loc_ramas_vacant)=1 and Data_plec not in ('01/01/1901','01/01/1900') and a.Data>dbo.EOM(i.Data_plec)
				raiserror(@mesaj,16,1)
			End	
			if exists (select 1 from resal r inner join inserted i on i.Marca=r.Marca 
				where convert(int,Loc_ramas_vacant)=1 and Data_plec not in ('01/01/1901','01/01/1900') and r.Data>dbo.EOM(i.Data_plec) and YEAR(r.Data)<3000)
			Begin
				select @mesaj='Eroare operare: Salariatul '+rtrim(i.Nume)+' marca ('+rtrim(i.Marca)+') are retineri pe luna ulterioara lunii de plecare !'
				from resal r inner join inserted i on i.Marca=r.Marca 
				where convert(int,Loc_ramas_vacant)=1 and Data_plec not in ('01/01/1901','01/01/1900') and r.Data>dbo.EOM(i.Data_plec) and YEAR(r.Data)<3000
				raiserror(@mesaj,16,1)
			End	

			declare @formaJuridica varchar(100)
			select @formaJuridica=val_alfanumerica from par where parametru='FJURIDICA'
			if nullif(@formaJuridica,'') is not null and UPDATE(Loc_ramas_vacant) and UPDATE(Data_plec)
			Begin
--	Verificam daca exista detasare activa pe marca - nu se permite incetarea unui contract de munca cat timp exista o detasare activa.
				if exists (select 1 from fRevisalDetasari ('01/01/1901', '12/31/2999', '', null) d 
						inner join inserted i on i.Marca=d.Marca and convert(int,i.Loc_ramas_vacant)=1 and i.Data_plec not in ('01/01/1901','01/01/1900')
					where isnull(convert(char(10),d.DataIncetare,102),'')<='1901/01/01')
				Begin
					select @mesaj='Eroare operare: Salariatul '+rtrim(i.Nume)+' marca ('+rtrim(i.Marca)+') are o detasare activa! Incetati detasarea si apoi incetati contractul de munca!'
					from fRevisalDetasari ('01/01/1901', '12/31/2999', '', null) d 
						inner join inserted i on i.Marca=d.Marca and convert(int,i.Loc_ramas_vacant)=1 and i.Data_plec not in ('01/01/1901','01/01/1900')
					where isnull(convert(char(10),d.DataIncetare,102),'')<='1901/01/01'
					raiserror(@mesaj,16,1)
				End

	--	Verificam daca exista suspendare activa pe marca - nu se permite incetarea unui contract de munca cat timp exista o suspendare activa.
				if exists (select 1 from fRevisalSuspendari ('01/01/1901', '12/31/2999', '') s 
						inner join inserted i on i.Marca=s.Marca and convert(int,Loc_ramas_vacant)=1 and i.Data_plec not in ('01/01/1901','01/01/1900')
					where isnull(convert(char(10),s.Data_incetare,102),'')<='1901/01/01')
				Begin
					select @mesaj='Eroare operare: Salariatul '+rtrim(i.Nume)+' marca ('+rtrim(i.Marca)+') are o suspendare activa! Incetati suspendarea si apoi incetati contractul de munca!'
					from fRevisalSuspendari ('01/01/1901', '12/31/2999', '') s 
						inner join inserted i on i.Marca=s.Marca and convert(int,i.Loc_ramas_vacant)=1 and i.Data_plec not in ('01/01/1901','01/01/1900')
					where isnull(convert(char(10),s.Data_incetare,102),'')<='1901/01/01'
					raiserror(@mesaj,16,1)
				End
			End
		End
	end 
	
end try
begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()+' (tr_validPersonal)'
	raiserror(@mesaj, 11, 1)
	RETURN
end catch

/*
	select * from Personal
*/

GO
Create trigger dbo.insert_ru_persoane on dbo.personal for insert, update /*, delete*/ not for replication
as
begin
--	momentan zice Nelutu sa nu tratam si pentru delete (nu prea se sterg datele din personal)
--	delete RU_persoane from RU_persoane p where exists (select d.Marca from deleted d where d.Marca=p.Marca) 

	if not exists (select p.Marca from RU_persoane p, inserted i where i.Marca=p.Marca)
		insert into RU_persoane
			(Tip, Marca, Email, Telefon_fix, Telefon_mobil, OpenID, Idmessenger, Idfacebook, ID_profesie, Diploma, CNP, Serie_BI, Numar_BI, Nume, Cod_functie, Loc_de_munca, 
			Judet, Localitate, Strada, Numar, Cod_postal, Bloc, Scara, Etaj, Apartament, Sector, Data_inreg, Detalii)
		select '1', Marca, '', '', '', '', '', '', null, '', Cod_numeric_personal, LEFT(Copii,2), substring(Copii,3,9), Nume, Cod_functie, Loc_de_munca,
			Judet, Localitate, Strada, Numar, Cod_postal, Bloc, Scara, Etaj, Apartament, Sector, convert(char(10),GETDATE(),101), ''
		from inserted i
	else
		update RU_persoane set Nume=i.Nume, CNP=i.Cod_numeric_personal, Serie_BI=LEFT(Copii,2), Numar_BI=substring(Copii,3,9), Cod_functie=i.Cod_functie, Loc_de_munca=i.Loc_de_munca, 
			Judet=i.Judet, Localitate=i.Localitate, Strada=i.Strada, Numar=i.Numar, Cod_postal=i.Cod_postal, Bloc=i.Bloc, Scara=i.Scara, Etaj=i.Etaj, 
			Apartament=i.Apartament, Sector=i.Sector
		from inserted i
		where RU_persoane.Marca=i.Marca
end
