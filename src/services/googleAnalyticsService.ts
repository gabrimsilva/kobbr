/**
 * Serviço de Google Analytics 4
 * 
 * IMPORTANTE: Este serviço é utilizado APENAS em páginas públicas (delivery, checkout, etc).
 * Páginas administrativas (/sistema/*) e de login NÃO são rastreadas.
 * 
 * Os eventos são enviados diretamente para o Google Analytics 4.
 * A tag do GA4 deve estar configurada no HTML.
 */

export type GAEventName =
  | 'page_view'
  | 'add_to_cart'
  | 'remove_from_cart'
  | 'view_cart'
  | 'begin_checkout'
  | 'purchase'
  | 'view_item'
  | 'view_item_list'
  | 'select_item'
  | 'add_payment_info'
  | 'add_shipping_info';

interface GAEventParams {
  [key: string]: any;
}

class GoogleAnalyticsService {
  private isGtagAvailable(): boolean {
    return typeof window !== 'undefined' && typeof window.gtag === 'function';
  }

  trackEvent(eventName: GAEventName, params?: GAEventParams): void {
    if (!this.isGtagAvailable()) return;
    try {
      window.gtag('event', eventName, params);
    } catch (error) {
      console.error('Erro ao enviar evento para GA4:', error);
    }
  }

  trackPageView(path: string, title?: string): void {
    this.trackEvent('page_view', {
      page_path: path,
      page_title: title || document.title,
    });
  }

  trackAddToCart(item: {
    id: string;
    name: string;
    category?: string;
    price: number;
    quantity: number;
  }): void {
    this.trackEvent('add_to_cart', {
      currency: 'BRL',
      value: item.price * item.quantity,
      items: [{
        item_id: item.id,
        item_name: item.name,
        item_category: item.category,
        price: item.price,
        quantity: item.quantity,
      }],
    });
  }

  trackRemoveFromCart(item: {
    id: string;
    name: string;
    category?: string;
    price: number;
    quantity: number;
  }): void {
    this.trackEvent('remove_from_cart', {
      currency: 'BRL',
      value: item.price * item.quantity,
      items: [{
        item_id: item.id,
        item_name: item.name,
        item_category: item.category,
        price: item.price,
        quantity: item.quantity,
      }],
    });
  }

  trackViewCart(items: Array<{
    id: string;
    name: string;
    category?: string;
    price: number;
    quantity: number;
  }>, totalValue: number): void {
    this.trackEvent('view_cart', {
      currency: 'BRL',
      value: totalValue,
      items: items.map(item => ({
        item_id: item.id,
        item_name: item.name,
        item_category: item.category,
        price: item.price,
        quantity: item.quantity,
      })),
    });
  }

  trackBeginCheckout(items: Array<{
    id: string;
    name: string;
    category?: string;
    price: number;
    quantity: number;
  }>, totalValue: number): void {
    this.trackEvent('begin_checkout', {
      currency: 'BRL',
      value: totalValue,
      items: items.map(item => ({
        item_id: item.id,
        item_name: item.name,
        item_category: item.category,
        price: item.price,
        quantity: item.quantity,
      })),
    });
  }

  trackPurchase(
    transactionId: string,
    items: Array<{
      id: string;
      name: string;
      category?: string;
      price: number;
      quantity: number;
    }>,
    totalValue: number,
    shipping: number = 0,
    paymentType?: string
  ): void {
    this.trackEvent('purchase', {
      transaction_id: transactionId,
      currency: 'BRL',
      value: totalValue,
      shipping: shipping,
      payment_type: paymentType,
      items: items.map(item => ({
        item_id: item.id,
        item_name: item.name,
        item_category: item.category,
        price: item.price,
        quantity: item.quantity,
      })),
    });
  }

  trackViewItem(item: {
    id: string;
    name: string;
    category?: string;
    price: number;
  }): void {
    this.trackEvent('view_item', {
      currency: 'BRL',
      value: item.price,
      items: [{
        item_id: item.id,
        item_name: item.name,
        item_category: item.category,
        price: item.price,
      }],
    });
  }

  trackViewItemList(
    items: Array<{
      id: string;
      name: string;
      category?: string;
      price: number;
    }>,
    listName: string
  ): void {
    this.trackEvent('view_item_list', {
      item_list_name: listName,
      items: items.map(item => ({
        item_id: item.id,
        item_name: item.name,
        item_category: item.category,
        price: item.price,
      })),
    });
  }

  trackSelectItem(item: {
    id: string;
    name: string;
    category?: string;
    price: number;
  }): void {
    this.trackEvent('select_item', {
      items: [{
        item_id: item.id,
        item_name: item.name,
        item_category: item.category,
        price: item.price,
      }],
    });
  }

  trackAddPaymentInfo(paymentType: string, value: number): void {
    this.trackEvent('add_payment_info', {
      currency: 'BRL',
      value: value,
      payment_type: paymentType,
    });
  }

  trackAddShippingInfo(shippingTier: string, value: number): void {
    this.trackEvent('add_shipping_info', {
      currency: 'BRL',
      value: value,
      shipping_tier: shippingTier,
    });
  }
}

declare global {
  interface Window {
    dataLayer: unknown[];
    gtag: (...args: unknown[]) => void;
  }
}

export const googleAnalytics = new GoogleAnalyticsService();
