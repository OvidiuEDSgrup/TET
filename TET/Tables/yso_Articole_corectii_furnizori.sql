CREATE TABLE dbo.yso_Articole_corectii
(
	idPozCor INT IDENTITY
		CONSTRAINT PK_yso_Articole_corectii 
				PRIMARY KEY CLUSTERED (idPozCor),
	[idPozADoc] INT 
		CONSTRAINT FK_yso_Art_corectii_PozADoc 
			FOREIGN KEY (idPozADoc) REFERENCES PozADoc(idPozADoc) NOT NULL, 
	subunit varchar(9) NOT NULL,
    tert VARCHAR(13) NOT NULL, 
	CONSTRAINT FK_yso_Art_corectii_Terti 
		FOREIGN KEY (subunit, tert) REFERENCES Terti(subunitate, tert),
	cod_articol VARCHAR(20) NOT NULL
		CONSTRAINT FK_yso_Art_corectii_Nomencl 
			FOREIGN KEY (cod_articol) REFERENCES Nomencl(cod), 
    cantitate DECIMAL(12, 3) NOT NULL, 
    pret DECIMAL(15, 5) NULL, 
    pret_valuta DECIMAL(15, 5) NULL
)
GO
CREATE UNIQUE INDEX [UQ_yso_Art_corectii_IDPozADoc_Cod_articol] ON dbo.yso_Articole_corectii (idPozADoc, cod_articol)
