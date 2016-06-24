CREATE TABLE [dbo].yso_Articole_corectii_furnizori
(
	[idPozADoc] INT 
		CONSTRAINT PK_yso_Articole_corectii_furnizori 
			PRIMARY KEY CLUSTERED (idPozADoc) 
		CONSTRAINT FK_yso_Art_cor_furn_PozADoc 
			FOREIGN KEY (idPozADoc) REFERENCES PozADoc(idPozADoc), 
	subunit varchar(9) NOT NULL,
    furnizor VARCHAR(13) NOT NULL, 
	CONSTRAINT FK_yso_Art_cor_furn_Terti 
		FOREIGN KEY (subunit, furnizor) REFERENCES Terti(subunitate, tert),
    cod_articol VARCHAR(20) NOT NULL
		CONSTRAINT FK_yso_Art_cor_furn_Nomencl 
		FOREIGN KEY (cod_articol) REFERENCES Nomencl(cod), 
    cantitate DECIMAL(12, 3) NOT NULL, 
    pret DECIMAL(15, 5) NULL, 
    pret_valuta DECIMAL(15, 5) NULL
)

GO

CREATE UNIQUE INDEX [UQ_yso_Art_cor_furn_IDPozADoc_Cod_articol] ON [dbo].[yso_Articole_corectii_furnizori] (idPozADoc, cod_articol)
