

exec sp_executesql N'INSERT INTO TET..pozdoc (Subunitate , Tip , Numar , Data , Numar_pozitie , Gestiune , Barcod , Cod , Contract , Cod_intrare , Cont_de_stoc , Cont_corespondent , Cont_intermediar , Cont_venituri , Gestiune_primitoare , Numar_DVI , Tert , Factura , Pret_de_stoc , Cantitate , Suprataxe_vama , Locatie , Adaos , Procent_vama , Pret_valuta , Discount , Pret_vanzare , Cota_TVA , TVA_deductibil , Pret_cu_amanuntul , TVA_neexigibil , Utilizator , Data_operarii , Ora_operarii , Tip_miscare , Data_expirarii , Loc_de_munca , Comanda , Stare , Pret_amanunt_predator , Accize_cumparare , Accize_datorate , Cont_factura , Grupa , Valuta , Curs , Data_facturii , Data_scadentei , Jurnal ) VALUES ( @P1 , @P2, @P3, @P4, @P5, @P6, @P7, @P8, @P9, @P10, @P11, @P12, @P13, @P14, @P15, @P16, @P17, @P18, @P19, @P20, @P21, @P22, @P23, @P24, @P25, @P26, @P27, @P28, @P29, @P30, @P31, @P32, @P33, @P34, @P35, @P36, @P37, @P38, @P39, @P40, @P41, @P42, @P43, @P44, @P45, @P46, @P47, @P48, @P49) ',N'@P1 char(1),@P2 char(2),@P3 char(2),@P4 datetime,@P5 int,@P6 char(3),@P7 varchar(1),@P8 char(7),@P9 char(1),@P10 char(10),@P11 char(4),@P12 char(4),@P13 varchar(1),@P14 char(4),@P15 char(3),@P16 char(14),@P17 char(13),@P18 char(2),@P19 float,@P20 float,@P21 float,@P22 char(6),@P23 real,@P24 real,@P25 float,@P26 real,@P27 float,@P28 real,@P29 float,@P30 float,@P31 real,@P32 char(6),@P33 datetime,@P34 char(6),@P35 char(1),@P36 datetime,@P37 char(1),@P38 varchar(1),@P39 smallint,@P40 float,@P41 float,@P42 float,@P43 char(4),@P44 char(4),@P45 varchar(1),@P46 float,@P47 datetime,@P48 datetime,@P49 varchar(1)','1','AP','25','2012-01-31 00:00:00',291,'300',' ','0003000','8','TEST10002B','3711','6071',' ','7071','378','4428         1','0212679091913','25',1540,1,0,'453567',-82.470001220703125,0,300,10,270,24,64.799999999999997,334.80000000000001,24,'OVIDIU','2011-12-09 00:00:00','005358','E','2012-01-31 00:00:00','1',' ',5,461.27999999999997,1,0,'4113','4427',' ',0,'2012-01-31 00:00:00','2012-02-20 00:00:00',' '



if 0=1
	/* din cauza indexului unic pe docsters ar putea sa crape daca in avizul initial exista doua pozitii cu acelasi cod si acelasi cod intrare...*/
	insert docsters
	(Subunitate, Tip, Numar, Data, Tert, Factura, Gestiune, Cod, Cod_intrare, Gestiune_primitoare, Cont, Cont_cor, Cantitate, Pret, Pret_vanzare, Jurnal, Utilizator, Data_operarii, Ora_operarii, Data_stergerii)
	select Subunitate, Tip, Numar, Data, Tert, Factura, Gestiune, Cod, Cod_intrare, Gestiune_primitoare, Cont_de_stoc, Cont_corespondent, Cantitate, Pret_de_stoc, Pret_vanzare, Jurnal, 'OVIDIU', Data_operarii, Ora_operarii, getdate()
	from pozdoc
	where subunitate='1        ' and tip='AP' and numar='25      ' and data='01/31/2012'

delete pozdoc
where subunitate='1        ' and tip='AP' and numar='25      ' and data='01/31/2012'

if 0=1
	update doc 
	set stare=1
	where subunitate='1        ' and tip='AP' and numar='25      ' and data='01/31/2012'
else
	delete doc 
	where subunitate='1        ' and tip='AP' and numar='25      ' and data='01/31/2012'
