
split_data <- function(df, prop = c(train, valid, test), seed = 28) {
  
  set.seed(seed)
  
  if (sum(prop) != 1) {
    stop("As proporções no vetor 'prop' devem somar 1!")
  }
  
  n_total <- nrow(df)
  indices <- sample(1:n_total)
  
  # pontos de corte
  n_train <- round(n_total * prop[1])
  n_valid <- round(n_total * prop[2])

  n_test  <- n_total - n_train - n_valid

  # partição  
  train_data <- df[indices[1:n_train], ]
  valid_data <- df[indices[(n_train + 1):(n_train + n_valid)], ]
  test_data  <- df[indices[(n_train + n_valid + 1):n_total], ]
  
  cat("--- Divisão dos Dados ---\n")
  cat("Treino:     ", nrow(train_data), " obs\n")
  cat("Validação:  ", nrow(valid_data), " obs\n")
  cat("Teste:      ", nrow(test_data), " obs\n")
  
  return(list(
    train = train_data,
    valid = valid_data,
    test  = test_data
  ))
}



quanti_var_plots <- function(v, nome_var = "Variável") {
  
  # --- ESTATÍSTICAS ----
  stats <- summary(v)
  skew  <- moments::skewness(v)  # Assimetria
  kurt  <- moments::kurtosis(v)  # Curtose
  
  cat("\n--- Estatísticas de", nome_var, "---\n")
  print(c(stats, "Skewness" = round(skew, 4), "Kurtosis" = round(kurt, 4)))

  
  df <- data.frame(valor = v)
  
  # --- HISTOGRAMA ---
  p1 <- ggplot(df, aes(x = valor)) +
    geom_histogram(aes(y = after_stat(density)), 
                            bins = 30, fill = "skyblue", color = "white", alpha = 0.7) +
    geom_density(color = "firebrick", linewidth = 1) +
    theme_minimal() +
    labs(title = paste("Histograma de", nome_var), y = "Densidade", x = NULL)
  
  # Boxplot Horizontal
  p2 <- ggplot(df, aes(x = valor)) +
    geom_boxplot(fill = "skyblue", color = "black", outlier.colour = "firebrick", alpha = 0.5) +
    theme_minimal() +
    labs(title = paste("Boxplot de", nome_var), x = nome_var) +
    theme(axis.text.y = element_blank(), 
                   axis.ticks.y = element_blank())
  
  painel <- p1 / p2 + patchwork::plot_layout(heights = c(3, 1))
  
  painel
}

quali_var_plots <- function(v, nome_var = "Variável") {
  
  # --- Tabela de Frequências ---
  freq_abs <- table(v, useNA = "ifany")
  freq_rel <- prop.table(freq_abs) * 100
  
  df_stats <- data.frame(
    Categoria = names(freq_abs),
    Frequencia = as.vector(freq_abs),
    Percentual = as.vector(freq_rel)
  )
  
  cat("\n--- Tabela de Frequências:", nome_var, "---\n")
  print(df_stats)
  
  # --- Gráfico de Barras ---
  p <- ggplot(df_stats, aes(x = Categoria, y = Frequencia, fill = Categoria)) +
    geom_bar(stat = "identity", color = "black", alpha = 0.7) +
    geom_text(aes(label = paste0(Frequencia, " (", round(Percentual, 1), "%)")),
                       vjust = -0.5, size = 3.5) +
    theme_minimal() +
    scale_fill_viridis_d(option = "mako", guide = "none") +
    labs(title = paste("Distribuição de Frequências:", nome_var),
                  x = nome_var,
                  y = "Contagem (N)") +
    ylim(0, max(df_stats$Frequencia) * 1.1)
  
  print(p)

}


quali_quali_analisy <- function(v1, v2, nome_v1 = "Var1", nome_v2 = "Var2") {
  
  # Tabela de Contingência
  tabela <- table(v1, v2, dnn = c(nome_v1, nome_v2))
  
  # Proporções
  tabela_prop <- prop.table(tabela, margin = 1) * 100
  
  # Teste Qui-Quadrado
  teste_q2 <- chisq.test(tabela, simulate.p.value = TRUE, B = 10000)
  
  # Teste Exato de Fisher
  #teste_fisher <- fisher.test(tabela)

  cat("--- Tabela de Contingência ---\n")
  print(tabela)
  
  cat("\n--- Proporções por Linha (%) ---\n")
  print(round(tabela_prop, 2))
  
  cat("\n--- Teste Qui-Quadrado de Independência ---\n")
  print(teste_q2)
  
  #cat("\n--- Teste Exato de Fisher ---\n")
  #print(teste_fisher)
  
}

gerar_matriz_correlacao <- function(dados_input) {
  
  # Criando o plot com ggpairs
  p <- ggpairs(dados_input,
               # Parte Superior: Correlação de Pearson
               upper = list(continuous = wrap("cor", method = "pearson", color = "blue")),
               
               # Diagonal Principal: Histogramas
               diag = list(continuous = wrap("barDiag", fill = "skyblue", color = "white")),
               
               # Parte Inferior: Scatterplots (Gráficos de Dispersão)
               lower = list(continuous = wrap("points", alpha = 0.5, color = "darkslategrey"))
  ) +
    theme_minimal() +
    theme(strip.text = element_text(face = "bold"))
  
  return(p)
}



quali_quanti_boxplot <- function(df, var_x, var_y, titulo = NULL) {
  
  if (is.null(titulo)) {
    titulo <- paste("Distribuição de", var_y, "por", var_x)
  }
  
  ggplot(df, aes(x = as.factor(.data[[var_x]]), y = .data[[var_y]], fill = as.factor(.data[[var_x]]))) +
    geom_boxplot(alpha = 0.7, outlier.color = "red", outlier.shape = 16) +
    theme_minimal() +
    labs(title = titulo,
         x = var_x,
         y = var_y) +
    scale_fill_viridis_d(option = "plasma", guide = "none")
}


plot_scatter <- function(x_vec, y_vec, nome_x = "X", nome_y = "Y") {
  
  df <- data.frame(x = x_vec, y = y_vec)
  
  # correlação de Pearson
  correlacao <- stats::cor(x_vec, y_vec, use = "complete.obs")
  
  # scatter plot
  p <- ggplot(df, aes(x = x, y = y)) +
    geom_point(color = "steelblue", alpha = 0.5, size = 2) +
    geom_smooth(method = "lm", color = "firebrick", se = TRUE) +
    theme_minimal() +
    labs(
      title = paste("Dispersão:", nome_y, "vs", nome_x),
      subtitle = paste("Correlação de Pearson:", round(correlacao, 3)),
      x = nome_x,
      y = nome_y
    )
  
  print(p)
}
plot_residuos_preditores <- function(modelo, dataset) {

  residuos <- resid(modelo)
  dataset_sincronizado <- dataset[names(residuos), , drop = FALSE]
  
  vars_na_formula <- all.vars(formula(modelo))
  nome_resposta <- vars_na_formula[1]

  preditores <- intersect(names(dataset_sincronizado), vars_na_formula[-1])
  
  n_pred <- length(preditores)
  if(n_pred == 0) stop("Nenhum preditor encontrado no dataset fornecido.")
  
  par(mfrow = c(ceiling(n_pred/3), 3), mar = c(4, 4, 3, 1))
  
  for (variavel in preditores) {
    x_val <- dataset_sincronizado[[variavel]]
    
    plot(x_val, residuos,
         main = paste("Resíduos vs", variavel),
         xlab = variavel,
         ylab = "Resíduos",
         pch = 19, 
         col = rgb(0.1, 0.2, 0.5, 0.5)) 
    
    abline(h = 0, col = "red", lwd = 2, lty = 2)
    
    if(is.numeric(x_val) && length(unique(x_val)) > 2) {
      lines(lowess(x_val, residuos), col = "darkgreen", lwd = 2)
    }
  }
  
  par(mfrow = c(1, 1))
}


