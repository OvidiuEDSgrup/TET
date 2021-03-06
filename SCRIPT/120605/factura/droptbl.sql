USE [TET]
GO
/****** Object:  Table [dbo].[pozadoc]    Script Date: 12/16/2011 17:06:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pozadoc]') AND type in (N'U'))
DROP TABLE [dbo].[pozadoc]
GO
/****** Object:  Table [dbo].[pozdoc]    Script Date: 12/16/2011 17:06:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pozdoc]') AND type in (N'U'))
DROP TABLE [dbo].[pozdoc]
GO
/****** Object:  Table [dbo].[DVI]    Script Date: 12/16/2011 17:06:46 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DVI]') AND type in (N'U'))
DROP TABLE [dbo].[DVI]
GO
/****** Object:  Table [dbo].[con]    Script Date: 12/16/2011 17:06:46 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[con]') AND type in (N'U'))
DROP TABLE [dbo].[con]
GO
/****** Object:  Table [dbo].[doc]    Script Date: 12/16/2011 17:06:46 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[doc]') AND type in (N'U'))
DROP TABLE [dbo].[doc]
GO
/****** Object:  Table [dbo].[docAnalize]    Script Date: 12/16/2011 17:06:46 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[docAnalize]') AND type in (N'U'))
DROP TABLE [dbo].[docAnalize]
GO
/****** Object:  Table [dbo].[docsters]    Script Date: 12/16/2011 17:06:46 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[docsters]') AND type in (N'U'))
DROP TABLE [dbo].[docsters]
GO
/****** Object:  Table [dbo].[extprogpl]    Script Date: 12/16/2011 17:06:46 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[extprogpl]') AND type in (N'U'))
DROP TABLE [dbo].[extprogpl]
GO
/****** Object:  Table [dbo].[factext]    Script Date: 12/16/2011 17:06:46 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[factext]') AND type in (N'U'))
DROP TABLE [dbo].[factext]
GO
/****** Object:  Table [dbo].[factimpl]    Script Date: 12/16/2011 17:06:46 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[factimpl]') AND type in (N'U'))
DROP TABLE [dbo].[factimpl]
GO
/****** Object:  Table [dbo].[factpos]    Script Date: 12/16/2011 17:06:46 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[factpos]') AND type in (N'U'))
DROP TABLE [dbo].[factpos]
GO
/****** Object:  Table [dbo].[factposleg]    Script Date: 12/16/2011 17:06:46 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[factposleg]') AND type in (N'U'))
DROP TABLE [dbo].[factposleg]
GO
/****** Object:  Table [dbo].[factrate]    Script Date: 12/16/2011 17:06:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[factrate]') AND type in (N'U'))
DROP TABLE [dbo].[factrate]
GO
/****** Object:  Table [dbo].[incfact]    Script Date: 12/16/2011 17:06:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[incfact]') AND type in (N'U'))
DROP TABLE [dbo].[incfact]
GO
/****** Object:  Table [dbo].[pozplin]    Script Date: 12/16/2011 17:06:48 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pozplin]') AND type in (N'U'))
DROP TABLE [dbo].[pozplin]
GO
/****** Object:  Table [dbo].[facturi]    Script Date: 12/16/2011 17:06:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[facturi]') AND type in (N'U'))
DROP TABLE [dbo].[facturi]
GO
/****** Object:  Table [dbo].[generareplati]    Script Date: 12/16/2011 17:06:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[generareplati]') AND type in (N'U'))
DROP TABLE [dbo].[generareplati]
GO
/****** Object:  Table [dbo].[impcurs]    Script Date: 12/16/2011 17:06:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[impcurs]') AND type in (N'U'))
DROP TABLE [dbo].[impcurs]
GO
/****** Object:  Table [dbo].[ImpExtras]    Script Date: 12/16/2011 17:06:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ImpExtras]') AND type in (N'U'))
DROP TABLE [dbo].[ImpExtras]
GO
/****** Object:  Table [dbo].[misMF]    Script Date: 12/16/2011 17:06:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[misMF]') AND type in (N'U'))
DROP TABLE [dbo].[misMF]
GO
/****** Object:  Table [dbo].[mismf_nu_sterge]    Script Date: 12/16/2011 17:06:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mismf_nu_sterge]') AND type in (N'U'))
DROP TABLE [dbo].[mismf_nu_sterge]
GO
/****** Object:  Table [dbo].[pdgrup]    Script Date: 12/16/2011 17:06:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pdgrup]') AND type in (N'U'))
DROP TABLE [dbo].[pdgrup]
GO
/****** Object:  Table [dbo].[ExpImpExtras]    Script Date: 12/16/2011 17:06:46 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ExpImpExtras]') AND type in (N'U'))
DROP TABLE [dbo].[ExpImpExtras]
GO
/****** Object:  Table [dbo].[adocsters]    Script Date: 12/16/2011 17:06:45 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[adocsters]') AND type in (N'U'))
DROP TABLE [dbo].[adocsters]
GO
/****** Object:  Table [dbo].[anexafac]    Script Date: 12/16/2011 17:06:46 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[anexafac]') AND type in (N'U'))
DROP TABLE [dbo].[anexafac]
GO
/****** Object:  Table [dbo].[antetBonuri]    Script Date: 12/16/2011 17:06:46 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[antetBonuri]') AND type in (N'U'))
DROP TABLE [dbo].[antetBonuri]
GO
/****** Object:  Table [dbo].[avnefac]    Script Date: 12/16/2011 17:06:46 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[avnefac]') AND type in (N'U'))
DROP TABLE [dbo].[avnefac]
GO
/****** Object:  Table [dbo].[combPozd]    Script Date: 12/16/2011 17:06:46 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[combPozd]') AND type in (N'U'))
DROP TABLE [dbo].[combPozd]
GO
/****** Object:  Table [dbo].[PozBord]    Script Date: 12/16/2011 17:06:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PozBord]') AND type in (N'U'))
DROP TABLE [dbo].[PozBord]
GO
/****** Object:  Table [dbo].[istfact]    Script Date: 12/16/2011 17:06:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[istfact]') AND type in (N'U'))
DROP TABLE [dbo].[istfact]
GO
/****** Object:  Table [dbo].[_pv]    Script Date: 12/16/2011 17:06:45 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[_pv]') AND type in (N'U'))
DROP TABLE [dbo].[_pv]
GO
/****** Object:  Table [dbo].[prog_plin]    Script Date: 12/16/2011 17:06:48 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[prog_plin]') AND type in (N'U'))
DROP TABLE [dbo].[prog_plin]
GO
/****** Object:  Table [dbo].[pvbon]    Script Date: 12/16/2011 17:06:48 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pvbon]') AND type in (N'U'))
DROP TABLE [dbo].[pvbon]
GO
/****** Object:  Table [dbo].[selfactachit]    Script Date: 12/16/2011 17:06:48 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[selfactachit]') AND type in (N'U'))
DROP TABLE [dbo].[selfactachit]
GO
/****** Object:  Table [dbo].[seriidocrs]    Script Date: 12/16/2011 17:06:48 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[seriidocrs]') AND type in (N'U'))
DROP TABLE [dbo].[seriidocrs]
GO
/****** Object:  Table [dbo].[sysscon]    Script Date: 12/16/2011 17:06:48 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysscon]') AND type in (N'U'))
DROP TABLE [dbo].[sysscon]
GO
/****** Object:  Table [dbo].[syssmm]    Script Date: 12/16/2011 17:06:48 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[syssmm]') AND type in (N'U'))
DROP TABLE [dbo].[syssmm]
GO
/****** Object:  Table [dbo].[sysspa]    Script Date: 12/16/2011 17:06:48 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysspa]') AND type in (N'U'))
DROP TABLE [dbo].[sysspa]
GO
/****** Object:  Table [dbo].[sysspcon]    Script Date: 12/16/2011 17:06:48 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysspcon]') AND type in (N'U'))
DROP TABLE [dbo].[sysspcon]
GO
/****** Object:  Table [dbo].[sysspd]    Script Date: 12/16/2011 17:06:48 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysspd]') AND type in (N'U'))
DROP TABLE [dbo].[sysspd]
GO
/****** Object:  Table [dbo].[sysspp]    Script Date: 12/16/2011 17:06:48 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysspp]') AND type in (N'U'))
DROP TABLE [dbo].[sysspp]
GO
